import 'package:flutter/material.dart';
import 'package:happening/features/calendar/calendar_event.dart';

/// Colored chip representing a single calendar event on the strip.
class EventBlock extends StatelessWidget {
  const EventBlock({
    super.key,
    required this.event,
    required this.width,
    required this.height,
    this.onHover,
  });

  final CalendarEvent event;
  final double width;
  final double height;
  final ValueChanged<CalendarEvent?>? onHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover?.call(event),
      onExit: (_) => onHover?.call(null),
      child: Container(
        width: width.clamp(2.0, double.infinity),
        height: height * 0.7,
        decoration: BoxDecoration(
          color: event.color.withOpacity(0.85),
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.centerLeft,
        child: width > 40
            ? Text(
                event.title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              )
            : null,
      ),
    );
  }
}
