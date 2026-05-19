// Root timeline widget with interactivity and layout management.
//
// TLDR:
// Overview: A stateful widget that integrates the clock, the painter, and the window resizing logic.
// Problem: Need to handle mouse hover and dynamically resize the window to show event details.
// Solution: Uses a Stack with MouseRegion and ExpansionLogic for state determination.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:logging/logging.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:happening/core/astro/astro_data_service.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/expansion_controller.dart';
import 'package:happening/core/window/physical_window_state.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/core/window/window_service_resize_executor.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:happening/features/timeline/focus/timeline_focus_controller.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';
import 'package:happening/features/timeline/moon_phase_badge.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_layout.dart';
import 'package:happening/features/timeline/timeline_painter.dart';

/// Root timeline widget. Driven by [clockService] stream.
class TimelineStrip extends StatefulWidget {
  const TimelineStrip({
    super.key,
    required this.events,
    required this.clockService,
    required this.settingsService,
    required this.onSignOut,
    required this.windowService,
    this.calendarController,
    this.onSignIn,
    this.onCancelSignIn,
    this.isLoading = false,
    this.enableAnimations = true,
    this.platformOverride,
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final CalendarController? calendarController;
  final SettingsService settingsService;
  final VoidCallback onSignOut;
  final WindowService windowService;

  /// When set, the strip renders a sign-in prompt instead of calendar content.
  final VoidCallback? onSignIn;

  /// When set, sign-in is in progress — strip shows "tap to cancel" and calls this on tap.
  final VoidCallback? onCancelSignIn;

  /// Whether calendar data is still being fetched for the first time.
  final bool isLoading;

  /// Whether to run repeating animations. Disable in tests to allow pumpAndSettle.
  final bool enableAnimations;
  final TargetPlatform? platformOverride;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip>
    with WidgetsBindingObserver {
  static final _log = Logger('_TimelineStripState');
  late final WindowService _windowService;
  late final ExpansionController _expansionController;
  late final TimelineFocusController _focusController;
  late final FocusNode _keyboardFocusNode;
  final _flashNotifier = ValueNotifier<double>(0.0);
  Timer? _flashTimer;
  late final AstroDataService _astroDataService;
  CalendarEvent? _hoveredEvent;
  bool _isHoveringStrip = false;
  PointerEvent? _lastPointerEvent;
  bool _isSettingsOpen = false;
  ExpansionState? _lastSentExpansionState;
  late Stream<DateTime> _paintTicks;
  late Stream<DateTime> _countdownTicks;
  String? _lastPaintStateDebug;

  void _updateAnimationTimer(Duration countdown) {
    if (!widget.enableAnimations) return;

    final needsAnimation = countdown.inSeconds > 0 && countdown.inMinutes < 2;

    if (needsAnimation && _flashTimer == null) {
      _flashTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _flashNotifier.value = (_flashNotifier.value + 0.2) % 1.0;
      });
    } else if (!needsAnimation && _flashTimer != null) {
      _flashTimer?.cancel();
      _flashTimer = null;
      _flashNotifier.value = 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _windowService = widget.windowService;
    _paintTicks = widget.clockService.tick10s;
    _countdownTicks = widget.clockService.tick1s;
    _expansionController = ExpansionController(
      executor: WindowServiceResizeExecutor(_windowService),
    )..start();
    _keyboardFocusNode = FocusNode(debugLabel: 'TimelineStripFocus');
    _focusController = TimelineFocusController(
      windowService: _windowService,
    );
    _focusController.isSentToBackNotifier.addListener(_onSentToBackChanged);

    // S5-FIX: Listen to settings changes to update heights and trigger rebuild
    widget.settingsService.addListener(_onSettingsChanged);

    _astroDataService =
        AstroDataService(settingsService: widget.settingsService);
    _astroDataService.addListener(_onAstroDataChanged);
    _astroDataService.initialize();

    WidgetsBinding.instance.addObserver(this);
    _updateHeights();
    unawaited(_syncWindowBehavior());
    _collidingIds = detectCollisions(widget.events);
    _log.fine('TimelineStrip: Initializing');
  }

  void _onAstroDataChanged() {
    _log.fine('TimelineStrip: astroData changed → '
        'current=${_astroDataService.current != null ? "AstroData(sunrise=${_astroDataService.current!.sunrise})" : "null"}');
    if (mounted) setState(() {});
  }

  void _onSettingsChanged() {
    if (mounted) {
      _updateHeights();
      unawaited(_syncWindowBehavior());
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(TimelineStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settingsService != widget.settingsService) {
      oldWidget.settingsService.removeListener(_onSettingsChanged);
      widget.settingsService.addListener(_onSettingsChanged);
      _updateHeights();
    }

    if (oldWidget.events != widget.events) {
      _collidingIds = detectCollisions(widget.events);
    }

    // When loading clears and the cursor is already over the strip, re-evaluate
    // hover with the stored pointer position.  Without this, the strip stays
    // collapsed until the user makes a new mouse move because _handleMouse only
    // fires on pointer events — it does not react to state changes on its own.
    if (oldWidget.isLoading && !widget.isLoading) {
      final last = _lastPointerEvent;
      if (_isHoveringStrip && last != null) {
        _handleMouse(last);
      }
    }

    if (oldWidget.clockService != widget.clockService) {
      _paintTicks = widget.clockService.tick10s;
      _countdownTicks = widget.clockService.tick1s;
      _now = widget.clockService.now;
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _focusController.isSentToBackNotifier.removeListener(_onSentToBackChanged);
    widget.settingsService.removeListener(_onSettingsChanged);
    _astroDataService.removeListener(_onAstroDataChanged);
    _astroDataService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _flashTimer?.cancel();

    _flashNotifier.dispose();
    _keyboardFocusNode.dispose();
    _focusController.dispose();
    super.dispose();
  }

  TargetPlatform get _targetPlatform {
    if (widget.platformOverride != null) return widget.platformOverride!;
    if (Platform.isMacOS) return TargetPlatform.macOS;
    if (Platform.isWindows) return TargetPlatform.windows;
    if (Platform.isLinux) return TargetPlatform.linux;
    return TargetPlatform.linux;
  }

  WindowMode _effectiveWindowMode() =>
      widget.settingsService.current.effectiveWindowMode;

  Future<void> _syncWindowBehavior() async {
    final effectiveMode = _effectiveWindowMode();
    await _focusController.setWindowMode(effectiveMode);
  }

  Future<void> _resetToFreshCollapsedState() async {
    final hadHoveredEvent = _hoveredEvent != null;
    _log.fine('TimelineStrip.resetFreshCollapsed START '
        'hovered=$hadHoveredEvent hovering=$_isHoveringStrip '
        'settings=$_isSettingsOpen '
        'sentToBack=${_focusController.isSentToBack} '
        'layout=${_layout != null} events=${widget.events.length}');


    _lastPaintStateDebug = null;
    if (mounted) {
      setState(() {
        _isSettingsOpen = false;
        _isHoveringStrip = false;
        _hoveredEvent = null;
        _layout = null;
      });
    }
    _expansionController.send(ExpansionState.collapsed);

    _log.fine('TimelineStrip.resetFreshCollapsed DONE '
        'hovered=${_hoveredEvent != null} hovering=$_isHoveringStrip '
        'settings=$_isSettingsOpen '
        'sentToBack=${_focusController.isSentToBack} '
        'layout=${_layout != null} events=${widget.events.length}');
  }

  void _onSentToBackChanged() {
    if (mounted) setState(() {});
  }

  TimelineLayout? _layout;
  DateTime _now = DateTime.now();
  Set<String> _collidingIds = const {};

  // WindowService owns the authoritative physical sizing.
  double get _collapsedHeight {
    return _windowService.getCollapsedHeight() -
        3; // Ensure WindowService is up to date with settings.
  }

  void _updateHeights() {
    _log.fine(
        'Timestrip: _updatgeHeights called:  strip height is to $_collapsedHeight');
    final settings = widget.settingsService.current;
    unawaited(_windowService.updateHeights(settings.fontSize));
  }

  // ── Focus / lifecycle handlers ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && !_isSettingsOpen) {
      setState(() {
        _isHoveringStrip = false;
        _hoveredEvent = null;
      });
      _expansionController.send(ExpansionState.collapsed);
    }
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _onMouseEnter(PointerEnterEvent event) {
    _handleMouse(event);
  }

  void _onMouseExit(PointerExitEvent event) {
    _handleMouse(event);
  }

  void _handleMouse(PointerEvent details) {
    _lastPointerEvent = details;
    if (_focusController.isSentToBack) return;
    final layout = _layout;
    if (layout == null) return;

    // 1. Calculate Dynamic Bounds
    final mouseX = details.localPosition.dx;
    final mouseY = details.localPosition.dy;
    final isOverStripZone = mouseY < _collapsedHeight;

    // S5-FIX: Sort events by duration ascending so shorter ones are prioritized
    // in hit-testing (latching the most specific event).
    final sortedEvents = [...widget.events]
      ..sort((a, b) => a.duration.compareTo(b.duration));

    final boundsMap = <String, EventBounds>{};
    for (final e in sortedEvents) {
      if (isOverStripZone) {
        final startX = layout.xForTime(e.startTime, _now);
        final endX = layout.effectiveEndX(e, _now);
        boundsMap[e.id] = EventBounds(
          left: startX,
          right: endX,
          top: 0,
          bottom: _collapsedHeight,
        );
      } else {
        final cardW = _cardWidth(layout.stripWidth, event: e);
        final cardL = _cardLeft(layout.stripWidth, event: e);
        boundsMap[e.id] = EventBounds(
          left: cardL,
          right: cardL + cardW,
          top: _collapsedHeight,
          bottom: 175,
        );
      }
    }

    final state = ExpansionLogic.determineState(
      details: details,
      eventBounds: boundsMap.values.toList(),
      stripHeight: _collapsedHeight,
      isSettingsOpen: _isSettingsOpen,
    );

    // 2. State Sync — prioritize current event to avoid jumping between overlapping bounds
    final isOverStrip = details is! PointerExitEvent && isOverStripZone;

    CalendarEvent? hit;
    // If already hovering, check if we stay inside that event's (possibly expanded) bounds first.
    // S5-FIX: Only latch if we are in the card zone (below strip). On the strip, we want precision switching.
    final shouldLatch = _hoveredEvent != null &&
        ExpansionLogic.shouldPrioritizeLatch(mouseY, _collapsedHeight);

    if (shouldLatch && boundsMap.containsKey(_hoveredEvent!.id)) {
      if (boundsMap[_hoveredEvent!.id]!.contains(mouseX, mouseY)) {
        hit = _hoveredEvent;
      }
    }

    // Otherwise, check all events in ascending duration order (shortest first).
    if (hit == null && state == ExpansionState.expanded) {
      for (final e in sortedEvents) {
        if (boundsMap[e.id]!.contains(mouseX, mouseY)) {
          hit = e;
          break;
        }
      }
    }

    if (state != _lastSentExpansionState) {
      _lastSentExpansionState = state;
      _log.fine('[TS] expansion → ${state.name} mouseX=${mouseX.toStringAsFixed(1)} mouseY=${mouseY.toStringAsFixed(1)} isExit=${details is PointerExitEvent}');
    }
    _expansionController.send(state);

    if (isOverStrip != _isHoveringStrip || hit?.id != _hoveredEvent?.id) {
      setState(() {
        _isHoveringStrip = isOverStrip;
        _hoveredEvent = hit;
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _cardLeft(double screenWidth, {CalendarEvent? event}) {
    final layout = _layout;
    final target = event ?? _hoveredEvent;
    if (layout == null || target == null) return 4.0;
    final startX = layout.xForTime(target.startTime, _now);
    final cardWidth = _cardWidth(screenWidth, event: target);
    return startX.clamp(4.0, math.max(4.0, screenWidth - cardWidth - 4.0));
  }

  double _cardWidth(double screenWidth, {CalendarEvent? event}) {
    const minCardWidth = 260.0;
    final layout = _layout;
    final target = event ?? _hoveredEvent;
    if (layout == null || target == null) return minCardWidth;
    final startX = layout.xForTime(target.startTime, _now);
    final endX = layout.xForTime(target.endTime, _now);
    return (endX - startX).abs().clamp(minCardWidth, double.infinity);
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
      _hoveredEvent = null;
    });
    if (_isSettingsOpen) {
      _expansionController.send(ExpansionState.expanded);
      unawaited(_windowService.focus());
    } else {
      _expansionController.send(ExpansionState.collapsed);
    }
  }

  Color _resolveCountdownColor(
      Duration remaining, Color base, double flashValue) {
    if (remaining <= Duration.zero) return Colors.red;
    if (remaining.inMinutes >= 5) return base;
    if (remaining.inMinutes < 2 && widget.enableAnimations) {
      return HSVColor.fromAHSV(1.0, flashValue * 360, 0.7, 1.0).toColor();
    }
    final factor = (5 - (remaining.inMilliseconds / 60000)).clamp(0.0, 1.0);
    return Color.lerp(base, Colors.red, factor)!;
  }

  void _debugPaintState({
    required bool isExpanded,
    required BoxConstraints constraints,
    required Color backdropColor,
    required Color painterBackgroundColor,
  }) {
    final cardVisible = widget.onSignIn == null &&
        widget.onCancelSignIn == null &&
        isExpanded &&
        !_isSettingsOpen &&
        _hoveredEvent != null;
    final settingsVisible = widget.onSignIn == null &&
        widget.onCancelSignIn == null &&
        _isSettingsOpen;
    final signature = [
      'expanded=$isExpanded',
      'card=$cardVisible',
      'settings=$settingsVisible',
      'hovered=${_hoveredEvent != null}',
      'hovering=$_isHoveringStrip',
      'sentToBack=${_focusController.isSentToBack}',
      'signIn=${widget.onSignIn != null}',
      'cancelSignIn=${widget.onCancelSignIn != null}',
      'loading=${widget.isLoading}',
      'layout=${_layout != null}',
      'events=${widget.events.length}',
      'collapsedH=${_collapsedHeight.toStringAsFixed(1)}',
      'expandedH=${_windowService.getExpandedHeight().toStringAsFixed(1)}',
      'backdrop=#${backdropColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'painterBg=#${painterBackgroundColor.toARGB32().toRadixString(16).padLeft(8, '0')}',
      'maxH=${constraints.maxHeight.toStringAsFixed(1)}',
    ].join(' ');
    if (signature == _lastPaintStateDebug) return;
    _lastPaintStateDebug = signature;
    _log.fine('TimelineStrip.paint-state $signature');
  }

  // ── Build ────────────────────────────────────────────────────────────────

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // _log.fine('Building $runtimeType');
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final fontSize = settings.fontSize.px;

    final stripBackgroundColor = theme.brightness == Brightness.dark
        ? const Color(0xFF1A1A2E)
        : Colors.white;
    final painterBackgroundColor = stripBackgroundColor;

    return StreamBuilder<PhysicalWindowState>(
      stream: _expansionController.stateStream,
      initialData: PhysicalWindowState.collapsed,
      builder: (context, expansionSnapshot) {
        final isExpanded = expansionSnapshot.data!.isExpanded;

        return StreamBuilder<DateTime>(
          stream: _paintTicks,
          initialData: widget.clockService.now,
          builder: (context, snapshot) {
            final now = snapshot.data!;
            _now = now;

            return LayoutBuilder(
              builder: (context, constraints) {
                final stripWidth = constraints.maxWidth;
                final nowIndicatorX = stripWidth * 0.10;

                final layout = TimelineLayout(
                  stripWidth: stripWidth,
                  nowIndicatorX: nowIndicatorX,
                  windowStart: now.subtract(Duration(
                      milliseconds: (settings.timeWindowHours * 3600000 * 0.125)
                          .toInt())),
                  windowEnd: now.add(Duration(
                      milliseconds: (settings.timeWindowHours * 3600000 * 0.875)
                          .toInt())),
                );
                _layout = layout;

                final active = layout.activeEvent(widget.events, now);
                final mode = active != null
                    ? CountdownMode.untilEnd
                    : CountdownMode.untilNext;
                const expandedBackdropColor = Colors.transparent;
                _debugPaintState(
                  isExpanded: isExpanded,
                  constraints: constraints,
                  backdropColor: expandedBackdropColor,
                  painterBackgroundColor: painterBackgroundColor,
                );

                return Focus(
                    focusNode: _keyboardFocusNode,
                    autofocus: true,
                    onKeyEvent: (node, event) => KeyEventResult.ignored,
                    child: MouseRegion(
                      onEnter: _onMouseEnter,
                      onHover: _handleMouse,
                      onExit: _onMouseExit,
                      hitTestBehavior: HitTestBehavior.translucent,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: isExpanded
                                ? _windowService.getExpandedHeight()
                                : constraints.maxHeight,
                            child:
                                const ColoredBox(color: expandedBackdropColor),
                          ),
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: _collapsedHeight,
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: TimelinePainter(
                                  events: widget.events,
                                  now: now,
                                  nowIndicatorX: nowIndicatorX,
                                  windowStart: layout.windowStart,
                                  windowEnd: layout.windowEnd,
                                  hoveredEventId: _hoveredEvent?.id,
                                  collidingIds: _collidingIds,
                                  fontSize: fontSize,
                                  backgroundColor: painterBackgroundColor,
                                  pastOverlayColor:
                                      theme.brightness == Brightness.dark
                                          ? Colors.black26
                                          : Colors.black12,
                                  nowLineColor: const Color(0xFFB71C1C),
                                  alwaysUse24HourFormat:
                                      MediaQuery.alwaysUse24HourFormatOf(
                                          context),
                                  tickColor: theme.textTheme.bodySmall?.color
                                          ?.withValues(alpha: 0.75) ??
                                      Colors.grey,
                                  isLoading: widget.isLoading,
                                  loadingTextColor:
                                      theme.textTheme.bodyMedium?.color ??
                                          Colors.white,
                                  isSignIn: widget.onSignIn != null ||
                                      widget.onCancelSignIn != null,
                                  isSigningIn: widget.onCancelSignIn != null,
                                  signInTextColor:
                                      theme.textTheme.bodyMedium?.color ??
                                          Colors.white,
                                  surfaceOpacity: 1.0,
                                  emphasisOpacity: 1.0,
                                  stripOpacity: settings.idleTimelineOpacity,
                                  astroData: _astroDataService.current,
                                  isAstroTheme: settings.theme ==
                                      AppTheme.astronomical,
                                ),
                              ),
                            ),
                          ),
                          if (widget.onSignIn != null ||
                              widget.onCancelSignIn != null)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  (widget.onCancelSignIn ?? widget.onSignIn)
                                      ?.call();
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const SizedBox.expand(),
                              ),
                            ),
                          if (widget.onSignIn == null &&
                              widget.onCancelSignIn == null)
                            Positioned(
                              left: mode == CountdownMode.untilEnd
                                  ? nowIndicatorX + 8
                                  : null,
                              right: mode == CountdownMode.untilNext
                                  ? stripWidth - nowIndicatorX + 8
                                  : null,
                              top: 0,
                              height: _collapsedHeight,
                              child: StreamBuilder<DateTime>(
                                stream: _countdownTicks,
                                initialData: now,
                                builder: (context, timeSnapshot) {
                                  final tickNow = timeSnapshot.data!;

                                  // Recompute active/target/mode/color with fresh time so
                                  // event-boundary transitions (e.g. start → end) are
                                  // reflected within 1s instead of waiting for tick10s.
                                  final tickActive = _layout?.activeEvent(
                                      widget.events, tickNow);
                                  final tickNextOverlap = tickActive != null
                                      ? (widget.events
                                              .where((e) =>
                                                  e.startTime
                                                      .isAfter(tickNow) &&
                                                  e.startTime.isBefore(
                                                      tickActive.endTime))
                                              .toList()
                                            ..sort((a, b) => a.startTime
                                                .compareTo(b.startTime)))
                                          .firstOrNull
                                      : null;
                                  final tickNextToStart = tickActive == null
                                      ? (widget.events
                                              .where((e) =>
                                                  e.startTime.isAfter(tickNow))
                                              .toList()
                                            ..sort((a, b) => a.startTime
                                                .compareTo(b.startTime)))
                                          .firstOrNull
                                      : null;
                                  final tickTarget = tickActive != null
                                      ? (tickNextOverlap?.startTime ??
                                          tickActive.endTime)
                                      : tickNextToStart?.startTime;
                                  final tickMode = tickActive != null
                                      ? CountdownMode.untilEnd
                                      : CountdownMode.untilNext;
                                  final tickBaseColor =
                                      tickMode == CountdownMode.untilEnd
                                          ? (theme.brightness == Brightness.dark
                                              ? Colors.amber
                                              : Colors.orange[800]!)
                                          : theme.textTheme.bodyMedium?.color ??
                                              Colors.white;

                                  final countdown = tickTarget != null
                                      ? layout.countdownTo(tickTarget, tickNow)
                                      : Duration.zero;

                                  _updateAnimationTimer(countdown);

                                  return ValueListenableBuilder<double>(
                                    valueListenable: _flashNotifier,
                                    builder: (context, flashValue, _) {
                                      final countdownColor =
                                          _resolveCountdownColor(countdown,
                                              tickBaseColor, flashValue);
                                      double countdownScale = 1.0;
                                      Offset shakeOffset = Offset.zero;
                                      if (countdown.inSeconds > 0 &&
                                          widget.enableAnimations) {
                                        if (countdown.inSeconds <= 120 &&
                                            countdown.inSeconds > 30) {
                                          countdownScale = 1.0 +
                                              (120 - countdown.inSeconds) /
                                                  90.0 *
                                                  2.0;
                                        } else if (countdown.inSeconds <= 30) {
                                          countdownScale = 3.0;
                                        }
                                        if (countdown.inSeconds <= 60) {
                                          shakeOffset = Offset(
                                              math.sin(flashValue *
                                                      8 *
                                                      math.pi) *
                                                  2.0,
                                              0);
                                        }
                                      }
                                      return Center(
                                        child: Transform.translate(
                                          offset: shakeOffset,
                                          child: Transform.scale(
                                            scale: countdownScale,
                                            child: CountdownDisplay(
                                              remaining: countdown,
                                              mode: tickMode,
                                              color: countdownColor,
                                              fontSize: fontSize,
                                              backgroundColor:
                                                  stripBackgroundColor,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          if (widget.onSignIn == null &&
                              widget.onCancelSignIn == null)
                            Positioned(
                              left: 8,
                              top: 0,
                              height: _collapsedHeight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _IconButton(
                                    icon: Icons.refresh,
                                    onTap: () {
                                      unawaited(_resetToFreshCollapsedState());
                                      unawaited(
                                          widget.calendarController!.refresh());
                                      unawaited(
                                          _windowService.reassertAppBar());
                                    },
                                    stripBackgroundColor: stripBackgroundColor,
                                  ),
                                  const SizedBox(width: 4),
                                  _IconButton(
                                    icon: Icons.flip_to_back,
                                    active: _focusController.isSentToBack,
                                    onTap: () {
                                      if (_focusController.isSentToBack) {
                                        unawaited(
                                            _focusController.restoreToFront());
                                      } else {
                                        unawaited(_focusController.sendToBack());
                                      }
                                    },
                                    stripBackgroundColor: stripBackgroundColor,
                                  ),
                                  const SizedBox(width: 4),
                                  if (_astroDataService.current != null) ...[
                                    MoonPhaseBadge(
                                      astroData: _astroDataService.current!,
                                      onTap: _toggleSettings,
                                      fontSize: fontSize,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  _IconButton(
                                    icon: Icons.settings,
                                    onTap: _toggleSettings,
                                    stripBackgroundColor: stripBackgroundColor,
                                  ),
                                ],
                              ),
                            ),
                          if (widget.onSignIn == null &&
                              widget.onCancelSignIn == null)
                            Positioned(
                              right: 8,
                              top: 0,
                              height: _collapsedHeight,
                              child: Center(
                                child: _IconButton(
                                  icon: Icons.power_settings_new,
                                  onTap: () => exit(0),
                                  stripBackgroundColor: stripBackgroundColor,
                                ),
                              ),
                            ),
                          if (widget.onSignIn == null &&
                              widget.onCancelSignIn == null &&
                              isExpanded &&
                              !_isSettingsOpen &&
                              _hoveredEvent != null)
                            Positioned(
                              top: _collapsedHeight,
                              left: _cardLeft(stripWidth),
                              child: HoverDetailOverlay(
                                event: _hoveredEvent!,
                                width: _cardWidth(stripWidth),
                              ),
                            ),
                          if (widget.onSignIn == null &&
                              widget.onCancelSignIn == null &&
                              _isSettingsOpen)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _toggleSettings,
                                behavior: HitTestBehavior.opaque,
                                child: Container(color: Colors.transparent),
                              ),
                            ),
                          if (widget.onSignIn == null &&
                              widget.onCancelSignIn == null &&
                              _isSettingsOpen)
                            Positioned(
                              top: _collapsedHeight,
                              left: 8,
                              bottom: 8,
                              child: SettingsPanel(
                                settingsService: widget.settingsService,
                                calendarController: widget.calendarController!,
                                onSignOut: widget.onSignOut,
                                platformOverride: _targetPlatform,
                              ),
                            ),
                        ],
                      ),
                    ));
              },
            );
          },
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
    required this.stripBackgroundColor,
    this.active = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color stripBackgroundColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active
              ? theme.colorScheme.primary.withValues(alpha: 0.25)
              : stripBackgroundColor.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 3,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: active
              ? theme.colorScheme.primary
              : (isDark ? Colors.white70 : Colors.black54),
          size: 16,
        ),
      ),
    );
  }
}
