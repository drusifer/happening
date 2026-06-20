import 'package:flutter/foundation.dart';
import 'package:happening/core/window/async_gate.dart';
import 'package:happening/core/window/strip_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:logging/logging.dart';

/// Owns the strip's logical [StripState] and exposes the transition API.
///
/// TLDR:
/// Overview: The controller in a conventional Flutter MVC split — owns model
///           state (which of the 3 [StripState]s) and the transition surface
///           (`collapse/expand/hide/show`). The widget is the view; geometry is
///           applied by [WindowService.applyState] (the OS executor).
/// Problem: Hide/expand/show/init each sequenced geometry directly from the
///           widget and service, drifting into N paths to the same end state.
/// Solution: A single [ChangeNotifier] holding truth, serialising every
///           transition through an [AsyncGate] (idempotent, last-wins) and
///           delegating the OS work to [WindowService.applyState].
/// Breaking Changes: No (not wired yet — introduced ahead of callers).
class StripController extends ChangeNotifier {
  StripController({required WindowService windowService})
      : _windowService = windowService {
    _gate = AsyncGate<StripState>(_apply)..start();
  }

  static final _log = Logger('StripController');

  final WindowService _windowService;
  late final AsyncGate<StripState> _gate;

  StripState _state = StripState.collapsedShown;

  /// The current logical state. Updated only after [WindowService.applyState]
  /// confirms, then listeners are notified.
  StripState get state => _state;

  /// Transition to the full-width collapsed strip (also the "show" target).
  Future<void> collapse() => _request(StripState.collapsedShown);

  /// Transition to the expanded (hover card / settings) strip.
  Future<void> expand() => _request(StripState.expandedShown);

  /// Transition to the hidden mini pill. Geometry collapses first by virtue of
  /// the mini size; there is no expanded-hidden state.
  Future<void> hide() => _request(StripState.hidden);

  /// Restore from hidden to the full-width collapsed strip.
  Future<void> show() => _request(StripState.collapsedShown);

  /// Re-apply the current state's geometry without changing it. Used for
  /// display/font-size changes where the logical state is unchanged but the
  /// computed geometry (width, origin, height) differs.
  Future<void> reapply() => _gate.send(_state, force: true);

  Future<void> _request(StripState s) => _gate.send(s);

  Future<void> _apply(StripState s) async {
    _log.fine('apply $s');
    await _windowService.applyState(s);
    if (_state != s) {
      _state = s;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _gate.dispose();
    super.dispose();
  }
}
