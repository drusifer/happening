// Root timeline widget with interactivity and layout management.
//
// TLDR:
// Overview: A stateful widget that integrates the clock, the painter, and the window resizing logic.
// Problem: Need to handle mouse hover and dynamically resize the window to show event details.
// Solution: Uses a Stack with MouseRegion, StreamBuilder, and window_manager resizing.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/time/clock_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/features/calendar/calendar_controller.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:happening/features/timeline/celebration_widget.dart';
import 'package:happening/features/timeline/countdown_display.dart';
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
    this.windowService,
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final CalendarController calendarController;
  final SettingsService settingsService;
  final VoidCallback onSignOut;
  /// Injectable for testing; defaults to [WindowService()] at runtime.
  final WindowService? windowService;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip> with SingleTickerProviderStateMixin {
  late final WindowService _windowService;
  late final AnimationController _flashController;
  bool _isExpanded = false;
  CalendarEvent? _hoveredEvent;
  double? _hoverX;
  bool _isHoveringStrip = false;
  bool _isSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    _windowService = widget.windowService ?? WindowService();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  // Updated each build — used by mouse handlers.
  TimelineLayout? _layout;
  DateTime _now = DateTime.now();
  double _collapsedHeight = 30.0;

  // ── Window expand/collapse guards ─────────────────────────────────────────

  Future<void> _expand() async {
    if (_isExpanded) return;
    _isExpanded = true;
    await _windowService.expand();
  }

  Future<void> _collapse() async {
    if (!_isExpanded) return;
    _isExpanded = false;
    await _windowService.collapse(height: _collapsedHeight);
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _onMouseMove(PointerEvent details) {
    setState(() {
      _isHoveringStrip = true;
      _hoverX = details.localPosition.dx;
    });

    // Ignore moves inside the card area — keep current hover state so buttons remain clickable.
    if (details.localPosition.dy >= _collapsedHeight) {
      if (_hoveredEvent != null || _isSettingsOpen) return;
    }

    final hit =
        _layout?.eventAtX(details.localPosition.dx, widget.events, _now);
    if (hit?.id == _hoveredEvent?.id) return;
    setState(() => _hoveredEvent = hit);

    if (hit != null || _isSettingsOpen) {
      unawaited(_expand());
    } else {
      unawaited(_collapse());
    }
  }

  void _onMouseExit(PointerEvent _) {
    setState(() {
      _isHoveringStrip = false;
      _hoveredEvent = null;
      _hoverX = null;
      _isSettingsOpen = false;
    });
    unawaited(_collapse());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<CalendarEvent> _futureEvents(DateTime now) {
    return widget.events.where((e) => !e.endTime.isBefore(now)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  double _cardLeft(double screenWidth) {
    final layout = _layout;
    final event = _hoveredEvent;
    if (layout == null || event == null) return 4.0;

    // Left-align card to the visible start of the event block (DEC-002)
    final visibleStart =
        layout.xForTime(event.startTime, _now).clamp(0.0, screenWidth);
    
    // Clamp to screen edges (4px padding)
    return visibleStart.clamp(4.0, screenWidth - 4.0);
  }

  double _cardWidth(double screenWidth) {
    const minCardWidth = 260.0;
    final layout = _layout;
    final event = _hoveredEvent;
    if (layout == null || event == null) return minCardWidth;

    final visibleStart =
        layout.xForTime(event.startTime, _now).clamp(0.0, screenWidth);
    final visibleEnd =
        layout.xForTime(event.endTime, _now).clamp(0.0, screenWidth);
    final eventWidth = (visibleEnd - visibleStart).abs();

    // Card width matches event block width, but is at least 260px (DEC-002).
    return eventWidth.clamp(minCardWidth, double.infinity);
  }

  void _toggleSettings() {
    setState(() {
      _isSettingsOpen = !_isSettingsOpen;
      _hoveredEvent = null;
    });
    if (_isSettingsOpen) {
      unawaited(_expand());
    } else {
      unawaited(_collapse());
    }
  }

  Color _resolveCountdownColor(Duration remaining, Color base) {
    if (remaining <= Duration.zero) return Colors.red;
    if (remaining.inMinutes >= 5) return base;

    if (remaining.inMinutes < 2) {
      // Rainbow hue cycle
      return HSVColor.fromAHSV(1.0, _flashController.value * 360, 0.7, 1.0).toColor();
    }

    // Interpolate base → red between 5 and 2 minutes
    final factor = (5 - (remaining.inMilliseconds / 60000)).clamp(0.0, 1.0);
    return Color.lerp(base, Colors.red, factor)!;
  }

  void _onTapDown(TapDownDetails details) {
    final hit = _layout?.eventAtX(details.localPosition.dx, widget.events, _now);
    if (hit != null) {
      setState(() => _hoveredEvent = hit);
      unawaited(_expand());
    } else if (!_isSettingsOpen) {
      setState(() => _hoveredEvent = null);
      unawaited(_collapse());
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = widget.settingsService.current;
    final fontSize = settings.fontSize.px;
    
    // Scale vertical strip height padding: Small -> +16, Medium -> +20, Large -> +24
    final padding = switch (settings.fontSize) {
      FontSize.small => 16.0,
      FontSize.medium => 20.0,
      FontSize.large => 24.0,
    };
    _collapsedHeight = fontSize + padding;

    const nowIndicatorFraction = 0.10; // 10% from left edge
    const pastFraction = 0.125; // 12.5% of the total window is past

    // S5-B3: Time window distribution
    final totalWindow = Duration(hours: settings.timeWindowHours);
    final windowPast = Duration(milliseconds: (totalWindow.inMilliseconds * pastFraction).toInt());
    final windowFuture = totalWindow - windowPast;

    final collidingIds = detectCollisions(widget.events);

    return StreamBuilder<DateTime>(
      stream: widget.clockService.tick,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data!;
        final future = _futureEvents(now);

        return AnimatedBuilder(
          animation: _flashController,
          builder: (context, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final stripWidth = constraints.maxWidth;
                final nowIndicatorX = stripWidth * nowIndicatorFraction;

                final layout = TimelineLayout(
                  stripWidth: stripWidth,
                  nowIndicatorX: nowIndicatorX,
                  windowStart: now.subtract(windowPast),
                  windowEnd: now.add(windowFuture),
                );

                _layout = layout;
                _now = now;

                final active = layout.activeEvent(widget.events, now);
                final nextEvent = future.isNotEmpty ? future.first : null;

                final mode = active != null
                    ? CountdownMode.untilEnd
                    : CountdownMode.untilNext;
                final countdown = nextEvent != null
                    ? layout.countdownTo(
                        active != null ? active.endTime : nextEvent.startTime, now)
                    : Duration.zero;

                final baseColor = mode == CountdownMode.untilEnd
                    ? (theme.brightness == Brightness.dark ? Colors.amber : Colors.orange[800]!)
                    : theme.textTheme.bodyMedium?.color ?? Colors.white;
                final countdownColor = _resolveCountdownColor(countdown, baseColor);

                // S5-D4/D5: Urgency effects (scaling & shaking)
                final remainingSeconds = countdown.inSeconds;
                double countdownScale = 1.0;
                Offset shakeOffset = Offset.zero;

                if (remainingSeconds > 0) {
                  if (remainingSeconds <= 120) {
                    // Gradual scale from 1.0 at 2m to 1.3 at 0m
                    countdownScale = 1.0 + (120 - remainingSeconds) / 120 * 0.3;
                  }
                  if (remainingSeconds <= 60) {
                    // Shake at 1m: 4Hz oscillation, 2px amplitude
                    final shakeX = math.sin(_flashController.value * 2 * math.pi * 4) * 2.0;
                    shakeOffset = Offset(shakeX, 0);
                  }
                }

                return MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringStrip = true),
                  onHover: _onMouseMove,
                  onExit: _onMouseExit,
                  child: GestureDetector(
                    onTapDown: _onTapDown,
                    behavior: HitTestBehavior.opaque,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Content layer
                      if (future.isEmpty)
                        const Positioned.fill(child: CelebrationWidget())
                      else ...[
                        // Timeline canvas — dynamic height (S5-B4)
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
                              windowStart: now.subtract(windowPast),
                              windowEnd: now.add(windowFuture),
                              hoveredEventId: _hoveredEvent?.id,
                              collidingIds: collidingIds,
                              countdownColor: countdownColor,
                              fontSize: settings.fontSize.px,
                              backgroundColor: theme.scaffoldBackgroundColor,
                              pastOverlayColor: theme.brightness == Brightness.dark
                                  ? Colors.black26
                                  : Colors.black12,
                                                        nowLineColor: theme.colorScheme.primary,
                                                        tickColor: theme.textTheme.bodySmall?.color?.withOpacity(0.5) ?? Colors.grey,
                                                      ),
                              
                          ),
                        ),

                        // Countdown label — Always left of the now line
                        Positioned(
                          right: stripWidth - nowIndicatorX + 4,
                          top: 0,
                          height: _collapsedHeight,
                          child: Center(
                            child: Transform.translate(
                              offset: shakeOffset,
                              child: Transform.scale(
                                scale: countdownScale,
                                child: CountdownDisplay(
                                  remaining: countdown,
                                  mode: mode,
                                  color: countdownColor,
                                  fontSize: settings.fontSize.px,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // S3-09: Hover-reveal controls (Gear + Refresh)
                      if (_isHoveringStrip)
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
                                color: theme.iconTheme.color?.withOpacity(0.7) ?? Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              _IconButton(
                                icon: Icons.settings,
                                onTap: _toggleSettings,
                                color: theme.iconTheme.color?.withOpacity(0.7) ?? Colors.white70,
                              ),
                            ],
                          ),
                        ),

                      // Hover detail card — visible when window is expanded
                      if (_hoveredEvent != null)
                        Positioned(
                          top: _collapsedHeight,
                          left: _cardLeft(stripWidth),
                          child: HoverDetailOverlay(
                            event: _hoveredEvent!,
                            width: _cardWidth(stripWidth),
                          ),
                        ),

                      // S3-10: Settings Panel
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
                ),
              );
            },
          );
          },
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color ?? Colors.white70,
          size: 16,
        ),
      ),
    );
  }
}
