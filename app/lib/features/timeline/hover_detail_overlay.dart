// Detailed event info card for hover states.
//
// TLDR:
// Overview: A card that shows full title, times, and meeting/calendar links.
// Problem: The 30px strip is too small to show full event details or buttons.
// Solution: Displays a shadow-boxed card that expands into the newly-resized window area.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card that expands downward from an event block on hover.
/// Rendered via OverlayEntry so it escapes the 30px strip bounds.
class HoverDetailOverlay extends StatelessWidget {
  const HoverDetailOverlay({super.key, required this.event, this.width = 260});

  final CalendarEvent event;
  final double width;

  static String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmt(event.startTime)} – ${_fmt(event.endTime)}',
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            if (event.calendarEventUrl != null ||
                event.videoCallUrl != null) ...[
              const SizedBox(height: 7),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (event.calendarEventUrl != null)
                    _LinkButton(
                        label: 'Open in Cal', url: event.calendarEventUrl!),
                  if (event.videoCallUrl != null)
                    _LinkButton(
                      label: 'Join Meeting',
                      url: event.videoCallUrl!,
                      highlight: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.label,
    required this.url,
    this.highlight = false,
  });

  final String label;
  final String url;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: highlight ? Colors.white24 : Colors.white12,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: highlight ? Colors.white60 : Colors.white30,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
