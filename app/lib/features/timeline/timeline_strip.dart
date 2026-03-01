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

const double _kNowIndicatorFraction = 0.10; // 10% from left edge
const double _kCollapsedHeight = 30.0;

/// Root timeline widget. Driven by [clockService] stream.
class TimelineStrip extends StatefulWidget {
  const TimelineStrip({
    super.key,
    required this.events,
    required this.clockService,
    required this.calendarController,
    required this.settingsService,
    required this.onSignOut,
    this.windowPast = const Duration(hours: 1),
    this.windowFuture = const Duration(hours: 8),
    this.windowService,
  });

  final List<CalendarEvent> events;
  final ClockService clockService;
  final CalendarController calendarController;
  final SettingsService settingsService;
  final VoidCallback onSignOut;
  final Duration windowPast;
  final Duration windowFuture;
  /// Injectable for testing; defaults to [WindowService()] at runtime.
  final WindowService? windowService;

  @override
  State<TimelineStrip> createState() => _TimelineStripState();
}

class _TimelineStripState extends State<TimelineStrip> {
  late final WindowService _windowService;
  bool _isExpanded = false;
  CalendarEvent? _hoveredEvent;
  double? _hoverX;
  bool _isHoveringStrip = false;
  bool _isSettingsOpen = false;

  @override
  void initState() {
    super.initState();
    _windowService = widget.windowService ?? WindowService();
  }

  // Updated each build — used by mouse handlers.
  TimelineLayout? _layout;
  DateTime _now = DateTime.now();

  // ── Window expand/collapse guards ─────────────────────────────────────────

  Future<void> _expand() async {
    if (_isExpanded) return;
    _isExpanded = true;
    await _windowService.expand();
  }

  Future<void> _collapse() async {
    if (!_isExpanded) return;
    _isExpanded = false;
    await _windowService.collapse();
  }

  // ── Mouse handlers ───────────────────────────────────────────────────────

  void _onMouseMove(PointerEvent details) {
    setState(() {
      _isHoveringStrip = true;
      _hoverX = details.localPosition.dx;
    });

    // Ignore moves inside the card area — keep current hover state so buttons remain clickable.
    if (details.localPosition.dy >= _kCollapsedHeight) {
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
    return widget.events.where((e) => e.endTime.isAfter(now)).toList()
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: widget.clockService.tick,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data!;
        final future = _futureEvents(now);

        return LayoutBuilder(
          builder: (context, constraints) {
            final stripWidth = constraints.maxWidth;
            final nowIndicatorX = stripWidth * _kNowIndicatorFraction;

            final layout = TimelineLayout(
              stripWidth: stripWidth,
              nowIndicatorX: nowIndicatorX,
              windowStart: now.subtract(widget.windowPast),
              windowEnd: now.add(widget.windowFuture),
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

            return MouseRegion(
              onEnter: (_) => setState(() => _isHoveringStrip = true),
              onHover: _onMouseMove,
              onExit: _onMouseExit,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Content layer
                  if (future.isEmpty)
                    const Positioned.fill(child: CelebrationWidget())
                  else ...[
                    // Timeline canvas — top 30px
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: _kCollapsedHeight,
                      child: CustomPaint(
                        painter: TimelinePainter(
                          events: widget.events,
                          now: now,
                          nowIndicatorX: nowIndicatorX,
                          windowStart: now.subtract(widget.windowPast),
                          windowEnd: now.add(widget.windowFuture),
                          hoveredEventId: _hoveredEvent?.id,
                          fontSize: widget.settingsService.current.fontSize.px,
                        ),
                      ),
                    ),

                    // Countdown label — right of the now indicator (S4-20/CR-02)
                    Positioned(
                      left: nowIndicatorX + 8,
                      top: 0,
                      height: _kCollapsedHeight,
                      child: Center(
                        child: CountdownDisplay(
                          remaining: countdown,
                          mode: mode,
                        ),
                      ),
                    ),
                  ],

                  // S3-09: Hover-reveal controls (Gear + Refresh)
                  if (_isHoveringStrip)
                    Positioned(
                      right: 8,
                      top: 0,
                      height: _kCollapsedHeight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconButton(
                            icon: Icons.refresh,
                            onTap: widget.calendarController.refresh,
                          ),
                          const SizedBox(width: 4),
                          _IconButton(
                            icon: Icons.settings,
                            onTap: _toggleSettings,
                          ),
                        ],
                      ),
                    ),

                  // Hover detail card — visible when window is expanded
                  if (_hoveredEvent != null)
                    Positioned(
                      top: _kCollapsedHeight,
                      left: _cardLeft(stripWidth),
                      child: HoverDetailOverlay(
                        event: _hoveredEvent!,
                        width: _cardWidth(stripWidth),
                      ),
                    ),

                  // S3-10: Settings Panel
                  if (_isSettingsOpen)
                    Positioned(
                      top: _kCollapsedHeight,
                      right: 8,
                      child: SettingsPanel(
                        settingsService: widget.settingsService,
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
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(
        icon,
        color: Colors.white70,
        size: 16,
      ),
    );
  }
}
