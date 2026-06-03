// Active display selection and hot-plug state machine.
//
// TLDR:
// Overview: ChangeNotifier that owns "which display the strip should be on
//           right now" — resolves the user's persisted choice against the
//           currently-connected displays, and tracks fallback/auto-return.
// Problem:  WindowService directly calls screen_retriever.getPrimaryDisplay,
//           with no way for the user to pick a non-primary display and no
//           recovery when a chosen display disconnects.
// Solution: DisplayService listens to screen_retriever events (debounced
//           250ms) and exposes activeDisplay, isInFallback, availableDisplays
//           to WindowService and SettingsPanel.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'display_id.dart';
import 'display_info.dart';
import 'persisted_display_choice.dart';

/// Reads current displays from the host platform. In production this is backed
/// by screen_retriever; tests inject a fake.
abstract class DisplayProbe {
  Future<List<DisplayInfo>> getAll();
}

/// Subscribes to host-level display change events. The callback fires when any
/// display is added, removed, or has its metrics changed. Multiple events
/// within a debounce window are coalesced into a single callback.
abstract class DisplayEvents {
  /// Returns a function to cancel the subscription.
  void Function() subscribe(void Function() onChange);
}

/// Resolves a persisted user choice against the current set of displays.
abstract class DisplayChoiceResolver {
  /// True iff the user has expressed a preference. A `NullChoiceResolver`
  /// (no preference) returns false; a fingerprint resolver constructed with
  /// a null/empty choice also returns false. Used by [DisplayService] to
  /// decide whether an unresolved choice means "in fallback" (preference
  /// exists but display gone) versus "no preference, just primary."
  bool get hasPreference;

  DisplayInfo? resolve(List<DisplayInfo> available);
}

class _NullChoiceResolver implements DisplayChoiceResolver {
  const _NullChoiceResolver();

  @override
  bool get hasPreference => false;

  @override
  DisplayInfo? resolve(List<DisplayInfo> available) => null;
}

class DisplayService extends ChangeNotifier {
  DisplayService({
    required DisplayProbe probe,
    required DisplayEvents events,
    PersistedDisplayChoice? initialChoice,
    DisplayChoiceResolver? choiceResolver,
    Duration debounce = const Duration(milliseconds: 250),
    Future<void> Function(Duration) sleep = _realSleep,
    this.onWeakMatch,
  })  : _probe = probe,
        _events = events,
        _choiceResolver = choiceResolver ??
            (initialChoice != null
                ? FingerprintChoiceResolver(initialChoice,
                    onWeakMatch: onWeakMatch)
                : const _NullChoiceResolver()),
        _debounce = debounce,
        _sleep = sleep;

  final DisplayProbe _probe;
  final DisplayEvents _events;
  DisplayChoiceResolver _choiceResolver;
  final Duration _debounce;
  final Future<void> Function(Duration) _sleep;
  final void Function(PersistedDisplayChoice choice, DisplayInfo display)?
      onWeakMatch;

  void Function()? _cancelSubscription;
  bool _initialized = false;
  bool _disposed = false;
  bool _refreshPending = false;
  bool _refreshInProgress = false;

  List<DisplayInfo> _available = const [];
  DisplayInfo? _active;
  DisplayInfo? _persistedChoiceMatch;
  bool _isInFallback = false;
  bool _wasJustAutoReturned = false;

  /// Currently-connected displays (sorted by labelFor's stable order convention).
  List<DisplayInfo> get availableDisplays => List.unmodifiable(_available);

  /// The display the strip should be rendered on right now. Either the
  /// user's persisted choice (when connected) or the primary fallback.
  DisplayInfo? get activeDisplay => _active;

  /// True iff the user has a persisted choice but it is not currently
  /// available — i.e., the strip is showing on primary as a fallback.
  bool get isInFallback => _isInFallback;

  /// True for the brief window after auto-return completes (consumed by the
  /// fallback-indicator widget to drive the fade+slide animation).
  bool get wasJustAutoReturned => _wasJustAutoReturned;

  /// Resolves to the persisted choice's currently-available DisplayInfo, or
  /// null if not connected.
  DisplayInfo? get persistedChoiceMatch => _persistedChoiceMatch;

  /// Replaces the choice resolver and triggers a refresh. Used when
  /// AppSettings.chosenDisplay changes (user picked a different display).
  Future<void> setChoiceResolver(DisplayChoiceResolver resolver) async {
    _choiceResolver = resolver;
    await _refresh();
  }

  /// Sets a new persisted display choice and triggers a refresh, using the
  /// registered [onWeakMatch] callback.
  Future<void> setPersistedChoice(PersistedDisplayChoice? choice) async {
    await setChoiceResolver(
      FingerprintChoiceResolver(choice, onWeakMatch: onWeakMatch),
    );
  }

  /// Loads the initial set of displays and subscribes to change events.
  /// Idempotent — safe to call once at app start.
  Future<void> initialize() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    _cancelSubscription = _events.subscribe(_onEvent);
    await _refresh();
  }

  void _onEvent() {
    if (_disposed) return;
    _refreshPending = true;
    if (_refreshInProgress) return;
    unawaited(_debouncedRefresh());
  }

  Future<void> _debouncedRefresh() async {
    _refreshInProgress = true;
    try {
      while (_refreshPending) {
        _refreshPending = false;
        await _sleep(_debounce);
        if (_disposed) return;
        await _refresh();
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> _refresh() async {
    if (_disposed) return;

    final next = await _probe.getAll();
    if (_disposed) return;

    final nextMatch = _choiceResolver.resolve(next);
    final nextActive = nextMatch ??
        (next.isEmpty
            ? null
            : next.firstWhere(
                (d) => d.isPrimary,
                orElse: () => next.first,
              ));
    final nextInFallback = nextMatch == null && _hasPersistedPreference();

    final autoReturned = _isInFallback && !nextInFallback && nextMatch != null;

    final changed = !_listEquals(next, _available) ||
        _active != nextActive ||
        _isInFallback != nextInFallback ||
        _persistedChoiceMatch != nextMatch;

    _available = next;
    _active = nextActive;
    _persistedChoiceMatch = nextMatch;
    _isInFallback = nextInFallback;
    _wasJustAutoReturned = autoReturned;

    if (changed) {
      notifyListeners();
    }
    if (autoReturned) {
      _wasJustAutoReturned = false;
    }
  }

  bool _hasPersistedPreference() => _choiceResolver.hasPreference;

  bool _listEquals(List<DisplayInfo> a, List<DisplayInfo> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSubscription?.call();
    _cancelSubscription = null;
    super.dispose();
  }
}

/// Matches a single persisted [DisplayId] by equality. Useful for tests and
/// as a simple in-session fallback. Real persistence across reboots uses
/// [FingerprintChoiceResolver].
class DisplayIdChoiceResolver implements DisplayChoiceResolver {
  const DisplayIdChoiceResolver(this.chosenId);
  final DisplayId chosenId;

  @override
  bool get hasPreference => true;

  @override
  DisplayInfo? resolve(List<DisplayInfo> available) {
    for (final d in available) {
      if (d.id == chosenId) return d;
    }
    return null;
  }
}

/// Resolves a [PersistedDisplayChoice] against the available displays using
/// the 3-tier match algorithm (exact → strong → weak). Used in production to
/// recover the user's persisted choice across app restarts where the raw
/// `Display.id` may not be stable.
///
/// Emits a warning to [onWeakMatch] when the fingerprint matches by name
/// only (different size or position) — useful for UI telemetry that wants
/// to inform the user "we picked your monitor but couldn't be sure."
class FingerprintChoiceResolver implements DisplayChoiceResolver {
  FingerprintChoiceResolver(
    this.choice, {
    this.onWeakMatch,
  });

  final PersistedDisplayChoice? choice;
  final void Function(PersistedDisplayChoice choice, DisplayInfo display)?
      onWeakMatch;

  @override
  bool get hasPreference => choice != null;

  @override
  DisplayInfo? resolve(List<DisplayInfo> available) {
    final c = choice;
    if (c == null) return null;
    final match = c.matchIn(available);
    if (match == null) return null;
    if (match.strength == PersistedDisplayChoiceMatchStrength.weak) {
      onWeakMatch?.call(c, match.display);
    }
    return match.display;
  }
}

Future<void> _realSleep(Duration d) => Future<void>.delayed(d);
