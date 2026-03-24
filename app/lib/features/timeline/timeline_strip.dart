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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/util/logger.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/countdown_display.dart';
import 'package:happening/features/timeline/expansion_logic.dart';
import 'package:happening/features/timeline/hover/hover_controller.dart';
import 'package:happening/features/timeline/hover_detail_overlay.dart';
import 'package:happening/features/timeline/settings_panel.dart';
import 'package:happening/features/timeline/timeline_layout.dart';
import 'package:happening/features/timeline/timeline_painter.dart';

/// Root timeline widget. Driven by [clockService] stream.
class TimelineStrip extends StatefulWidget {
  const TimelineStrip({
    super.key,
    required this.events,
    required this.clockService,
    required this.calendarController,
    required this.settingsService,
    required this.onSignOut,
    required this.windowService,
    this.isLoading = false,
    this.enableAnimations = true,
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final CalendarController calendarController;
  final SettingsService settingsService;
  final VoidCallback onSignOut;
  final WindowService windowService;

  /// Whether calendar data is still being fetched for the first time.
  final bool isLoading;

  /// Whether to run repeating animations. Disable in tests to allow pumpAndSettle.
  final bool enableAnimations;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip>
    with WidgetsBindingObserver {
  late final WindowService _windowService;
  late final HoverController _hoverController;
  final _flashNotifier = ValueNotifier<double>(0.0);
  Timer? _flashTimer;
  CalendarEvent? _hoveredEvent;
  bool _isHoveringStrip = false;
  bool _isSettingsOpen = false;

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
    _hoverController = HoverController.create(_windowService);
    _windowService.isExpandedNotifier.addListener(_onExpansionChanged);

    // S5-FIX: Listen to settings changes to update heights and trigger rebuild
    widget.settingsService.addListener(_onSettingsChanged);

    WidgetsBinding.instance.addObserver(this);
    _updateHeights();
    _collidingIds = detectCollisions(widget.events);
    unawaited(AppLogger.debug('TimelineStrip: Initializing'));
    // ALWAYS call collapse on init to force initial state regardless of OS/service previous state.
    unawaited(_windowService.collapse());
  }

  void _onSettingsChanged() {
    if (mounted) {
      _updateHeights();
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
  }

  @override
  void dispose() {
    _windowService.isExpandedNotifier.removeListener(_onExpansionChanged);
    widget.settingsService.removeListener(_onSettingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    _hoverController.dispose();
    _flashTimer?.cancel();
    _flashNotifier.dispose();
    super.dispose();
  }

  void _onExpansionChanged() {
    if (mounted) {
      setState(() {});
    }
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
    unawaited(AppLogger.debug(
        'Timestrip: _updatgeHeights called:  strip height is to $_collapsedHeight'));
    final settings = widget.settingsService.current;
    unawaited(_windowService.updateHeights(settings.fontSize));
  }

  // ── Focus / lifecycle handlers ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // S5-FIX: Focus-based expansion logic is fragile on Linux.
    // We only use this to trigger a collapse if settings are closed and we lose focus.
    if (state != AppLifecycleState.resumed && !_isSettingsOpen) {
      if (_windowService.isExpandedNotifier.value) {
        setState(() {
          _isHoveringStrip = false;
          _hoveredEvent = null;
        });
        unawaited(_windowService.collapse());
      }
    }
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _handleMouse(PointerEvent details) {
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

    if (isOverStrip != _isHoveringStrip || hit?.id != _hoveredEvent?.id) {
      unawaited(AppLogger.debug(
          '${details.runtimeType}: ${hit?.title ?? (isOverStrip ? 'Strip' : 'Outside')}'));
      setState(() {
        _isHoveringStrip = isOverStrip;
        _hoveredEvent = hit;
      });
    }

    // 3. Window Execution — routed through HoverController.
    // On Linux, LinuxHoverController suppresses spurious collapses fired by
    // GTK's synthetic pointer-exit during window resize (300ms window).
    _hoverController.setIntent(state);
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
      if (!_windowService.isExpandedNotifier.value) {
        unawaited(_windowService.expand());
      }
    } else {
      if (_windowService.isExpandedNotifier.value) {
        unawaited(_windowService.collapse());
      }
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    unawaited(AppLogger.debug('Building ${runtimeType}'));
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final fontSize = settings.fontSize.px;

    return StreamBuilder<DateTime>(
      stream: widget.clockService.tick10s,
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
                  milliseconds:
                      (settings.timeWindowHours * 3600000 * 0.125).toInt())),
              windowEnd: now.add(Duration(
                  milliseconds:
                      (settings.timeWindowHours * 3600000 * 0.875).toInt())),
            );
            _layout = layout;

            final active = layout.activeEvent(widget.events, now);
            final mode = active != null
                ? CountdownMode.untilEnd
                : CountdownMode.untilNext;

            final nextOverlap = active != null
                ? (widget.events
                        .where((e) =>
                            e.startTime.isAfter(now) &&
                            e.startTime.isBefore(active.endTime))
                        .toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                    .firstOrNull
                : null;

            final nextToStart =
                (widget.events.where((e) => e.startTime.isAfter(now)).toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                    .firstOrNull;
            final DateTime? countdownTarget = active != null
                ? (nextOverlap?.startTime ?? active.endTime)
                : nextToStart?.startTime;

            final baseColor = mode == CountdownMode.untilEnd
                ? (theme.brightness == Brightness.dark
                    ? Colors.amber
                    : Colors.orange[800]!)
                : theme.textTheme.bodyMedium?.color ?? Colors.white;

            final stripBackgroundColor = theme.brightness == Brightness.dark
                ? const Color(0xFF1A1A2E)
                : Colors.white;

            final isExpanded = _windowService.isExpandedNotifier.value;
            AppLogger.debug(
                'TimelineStrip: Layout isExpanded=$isExpanded _collapsedHeight=$_collapsedHeight maxHeight=${constraints.maxHeight}');

            return MouseRegion(
              onEnter: _handleMouse,
              onHover: _handleMouse,
              onExit: _handleMouse,
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
                    child: Container(
                      color: isExpanded && Platform.isWindows
                          ? Colors.transparent
                          : stripBackgroundColor,
                    ),
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
                          backgroundColor: stripBackgroundColor,
                          pastOverlayColor: theme.brightness == Brightness.dark
                              ? Colors.black26
                              : Colors.black12,
                          nowLineColor: const Color(0xFFB71C1C),
                          tickColor: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.75) ??
                              Colors.grey,
                          isLoading: widget.isLoading,
                          loadingTextColor:
                              theme.textTheme.bodyMedium?.color ?? Colors.white,
                        ),
                      ),
                    ),
                  ),
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
                      stream: widget.clockService.tick1s,
                      initialData: now,
                      builder: (context, timeSnapshot) {
                        final tickNow = timeSnapshot.data!;

                        // Recompute active/target/mode/color with fresh time so
                        // event-boundary transitions (e.g. start → end) are
                        // reflected within 1s instead of waiting for tick10s.
                        final tickActive =
                            _layout?.activeEvent(widget.events, tickNow);
                        final tickNextOverlap = tickActive != null
                            ? (widget.events
                                    .where((e) =>
                                        e.startTime.isAfter(tickNow) &&
                                        e.startTime
                                            .isBefore(tickActive.endTime))
                                    .toList()
                                  ..sort((a, b) =>
                                      a.startTime.compareTo(b.startTime)))
                                .firstOrNull
                            : null;
                        final tickNextToStart = tickActive == null
                            ? (widget.events
                                    .where((e) => e.startTime.isAfter(tickNow))
                                    .toList()
                                  ..sort((a, b) =>
                                      a.startTime.compareTo(b.startTime)))
                                .firstOrNull
                            : null;
                        final tickTarget = tickActive != null
                            ? (tickNextOverlap?.startTime ?? tickActive.endTime)
                            : tickNextToStart?.startTime;
                        final tickMode = tickActive != null
                            ? CountdownMode.untilEnd
                            : CountdownMode.untilNext;
                        final tickBaseColor = tickMode == CountdownMode.untilEnd
                            ? (theme.brightness == Brightness.dark
                                ? Colors.amber
                                : Colors.orange[800]!)
                            : theme.textTheme.bodyMedium?.color ?? Colors.white;

                        final countdown = tickTarget != null
                            ? layout.countdownTo(tickTarget, tickNow)
                            : Duration.zero;

                        _updateAnimationTimer(countdown);

                        return ValueListenableBuilder<double>(
                          valueListenable: _flashNotifier,
                          builder: (context, flashValue, _) {
                            final countdownColor = _resolveCountdownColor(
                                countdown, tickBaseColor, flashValue);
                            double countdownScale = 1.0;
                            Offset shakeOffset = Offset.zero;
                            if (countdown.inSeconds > 0 &&
                                widget.enableAnimations) {
                              if (countdown.inSeconds <= 120 &&
                                  countdown.inSeconds > 30) {
                                countdownScale = 1.0 +
                                    (120 - countdown.inSeconds) / 90.0 * 2.0;
                              } else if (countdown.inSeconds <= 30) {
                                countdownScale = 3.0;
                              }
                              if (countdown.inSeconds <= 60) {
                                shakeOffset = Offset(
                                    math.sin(flashValue * 8 * math.pi) * 2.0,
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
                                    backgroundColor: stripBackgroundColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 0,
                    height: _collapsedHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _IconButton(
                          icon: Icons.refresh,
                          onTap: widget.calendarController.refresh,
                          stripBackgroundColor: stripBackgroundColor,
                        ),
                        const SizedBox(width: 4),
                        _IconButton(
                          icon: Icons.settings,
                          onTap: _toggleSettings,
                          stripBackgroundColor: stripBackgroundColor,
                        ),
                      ],
                    ),
                  ),
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
                  if (_windowService.isExpandedNotifier.value &&
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
                  if (_isSettingsOpen)
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _toggleSettings,
                        behavior: HitTestBehavior.opaque,
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  if (_isSettingsOpen)
                    Positioned(
                      top: _collapsedHeight,
                      left: 8,
                      child: SettingsPanel(
                        settingsService: widget.settingsService,
                        calendarController: widget.calendarController,
                        onSignOut: widget.onSignOut,
                      ),
                    ),
                ],
              ),
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
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color stripBackgroundColor;

  @override
  Widget build(BuildContext context) {
    unawaited(AppLogger.debug('Building ${runtimeType}'));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: stripBackgroundColor.withValues(alpha: 0.92),
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
          color: isDark ? Colors.white70 : Colors.black54,
          size: 16,
        ),
      ),
    );
  }
}
