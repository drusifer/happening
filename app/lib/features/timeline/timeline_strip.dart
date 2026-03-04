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
    this.enableAnimations = true,
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final CalendarController calendarController;
  final SettingsService settingsService;
  final VoidCallback onSignOut;
  final WindowService windowService;

  /// Whether to run repeating animations. Disable in tests to allow pumpAndSettle.
  final bool enableAnimations;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip>
    with WidgetsBindingObserver {
  late final WindowService _windowService;
  final _flashNotifier = ValueNotifier<double>(0.0);
  Timer? _flashTimer;
  CalendarEvent? _hoveredEvent;
  bool _isHoveringStrip = false;
  bool _isSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    _windowService = widget.windowService;
    if (widget.enableAnimations) {
      _flashTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        _flashNotifier.value = (_flashNotifier.value + 0.2) % 1.0;
      });
    }

    WidgetsBinding.instance.addObserver(this);
    _updateHeights();
    unawaited(AppLogger.debug('TimelineStrip: Initializing collapsedHeight=$_collapsedHeight expandedHeight=$_expandedHeight'));
    // ALWAYS call collapse on init to force initial state regardless of OS/service previous state.
    unawaited(_windowService.collapse(height: _collapsedHeight));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flashTimer?.cancel();
    _flashNotifier.dispose();
    super.dispose();
  }

  TimelineLayout? _layout;
  DateTime _now = DateTime.now();
  Set<String> _collidingIds = const {};
  double _ogCollapsedHeight = 35.0;
  double _ogExpandedHeight = 190.0;
  double _collapsedHeight = 35.0;
  double _expandedHeight = 0;

  void _updateHeights() {
    final settings = widget.settingsService.current;
    final fontSize = settings.fontSize.px;
    _collapsedHeight = _ogCollapsedHeight + fontSize * 1.1;
    _expandedHeight = _ogExpandedHeight + fontSize * 4;
  }

  // ── Focus / lifecycle handlers ────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // S5-FIX: Focus-based expansion logic is fragile on Linux. 
    // We only use this to trigger a collapse if settings are closed and we lose focus.
    if (state != AppLifecycleState.resumed && !_isSettingsOpen) {
      if (_windowService.isExpanded) {
        setState(() {
          _isHoveringStrip = false;
          _hoveredEvent = null;
        });
        unawaited(_windowService.collapse(height: _collapsedHeight));
      }
    }
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _handleMouse(PointerEvent details) {
    final layout = _layout;
    if (layout == null) return;

    _updateHeights();

    // 1. Expansion Logic
    final bounds = widget.events.map((e) {
      final startX = layout.xForTime(e.startTime, _now);
      final endX = layout.effectiveEndX(e, _now);
      return EventBounds(
        left: startX,
        right: endX,
        top: 0,
        bottom: 175,
      );
    }).toList();

    final state = ExpansionLogic.determineState(
      details: details,
      eventBounds: bounds,
      stripHeight: _collapsedHeight,
      isSettingsOpen: _isSettingsOpen,
    );

    // 2. State Sync — only setState when something actually changed.
    final isOverStrip =
        details is! PointerExitEvent && details.localPosition.dy < _collapsedHeight;
    final hit = (state == ExpansionState.expanded)
        ? layout.eventAtX(details.localPosition.dx, widget.events, _now)
        : null;

    if (isOverStrip != _isHoveringStrip || hit?.id != _hoveredEvent?.id) {
      unawaited(AppLogger.debug('${details.runtimeType}: ${hit?.title ?? (isOverStrip ? 'Strip' : 'Outside')}'));
      setState(() {
        _isHoveringStrip = isOverStrip;
        _hoveredEvent = hit;
      });
    }

    // 3. Window Execution (Gated by UI state)
    if (state == ExpansionState.expanded) {
      if (!_windowService.isExpanded) {
        unawaited(AppLogger.debug('TimelineStrip: Executing expand threshold=$_expandedHeight'));
        unawaited(_windowService.expand(height: _expandedHeight));
      }
    } else {
      if (_windowService.isExpanded) {
        unawaited(AppLogger.debug('TimelineStrip: Executing collapse height=$_collapsedHeight'));
        unawaited(_windowService.collapse(height: _collapsedHeight));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  double _cardLeft(double screenWidth) {
    final layout = _layout;
    final event = _hoveredEvent;
    if (layout == null || event == null) return 4.0;
    final startX = layout.xForTime(event.startTime, _now);
    final cardWidth = _cardWidth(screenWidth);
    return startX.clamp(4.0, math.max(4.0, screenWidth - cardWidth - 4.0));
  }

  double _cardWidth(double screenWidth) {
    const minCardWidth = 260.0;
    final layout = _layout;
    final event = _hoveredEvent;
    if (layout == null || event == null) return minCardWidth;
    final startX = layout.xForTime(event.startTime, _now);
    final endX = layout.xForTime(event.endTime, _now);
    return (endX - startX).abs().clamp(minCardWidth, double.infinity);
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
      _hoveredEvent = null;
    });
    if (_isSettingsOpen) {
      if (!_windowService.isExpanded) {
        unawaited(_windowService.expand(height: _expandedHeight));
      }
    } else {
      if (_windowService.isExpanded) {
        unawaited(_windowService.collapse(height: _collapsedHeight));
      }
    }
  }

  Color _resolveCountdownColor(Duration remaining, Color base, double flashValue) {
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
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final fontSize = settings.fontSize.px;
    _updateHeights();

    return StreamBuilder<DateTime>(
      stream: widget.clockService.tick,
      initialData: widget.clockService.now,
      builder: (context, snapshot) {
        final now = snapshot.data!;
        _now = now;
        _collidingIds = detectCollisions(widget.events);

        return LayoutBuilder(
          builder: (context, constraints) {
            final stripWidth = constraints.maxWidth;
            final nowIndicatorX = stripWidth * 0.10;

            final layout = TimelineLayout(
              stripWidth: stripWidth,
              nowIndicatorX: nowIndicatorX,
              windowStart: now.subtract(Duration(
                  milliseconds: (settings.timeWindowHours * 3600000 * 0.125).toInt())),
              windowEnd: now.add(Duration(
                  milliseconds: (settings.timeWindowHours * 3600000 * 0.875).toInt())),
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

            final nextToStart = (widget.events
                    .where((e) => e.startTime.isAfter(now))
                    .toList()
                  ..sort((a, b) => a.startTime.compareTo(b.startTime)))
                .firstOrNull;
            final DateTime? countdownTarget = active != null
                ? (nextOverlap?.startTime ?? active.endTime)
                : nextToStart?.startTime;
            final countdown = countdownTarget != null
                ? layout.countdownTo(countdownTarget, now)
                : Duration.zero;

            final baseColor = mode == CountdownMode.untilEnd
                ? (theme.brightness == Brightness.dark
                    ? Colors.amber
                    : Colors.orange[800]!)
                : theme.textTheme.bodyMedium?.color ?? Colors.white;

            final stripBackgroundColor =
                theme.brightness == Brightness.dark ? const Color(0xFF1A1A2E) : Colors.white;

            return MouseRegion(
              onEnter: _handleMouse,
              onHover: _handleMouse,
              onExit: _handleMouse,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _collapsedHeight,
                    child: Container(color: stripBackgroundColor),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _collapsedHeight,
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
                        tickColor: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.75) ??
                            Colors.grey,
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
                    child: ValueListenableBuilder<double>(
                      valueListenable: _flashNotifier,
                      builder: (context, flashValue, _) {
                        final countdownColor = _resolveCountdownColor(countdown, baseColor, flashValue);
                        double countdownScale = 1.0;
                        Offset shakeOffset = Offset.zero;
                        if (countdown.inSeconds > 0 && widget.enableAnimations) {
                          if (countdown.inSeconds <= 120 && countdown.inSeconds > 30) {
                            countdownScale =
                                1.0 + (120 - countdown.inSeconds) / 90.0 * 2.0;
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
                                mode: mode,
                                color: countdownColor,
                                fontSize: fontSize,
                                backgroundColor: stripBackgroundColor,
                              ),
                            ),
                          ),
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
                  if (_windowService.isExpanded && !_isSettingsOpen && _hoveredEvent != null)
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
