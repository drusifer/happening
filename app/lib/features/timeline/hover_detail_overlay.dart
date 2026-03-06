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
class HoverDetailOverlay extends StatelessWidget {
  const HoverDetailOverlay({
    super.key,
    required this.event,
    this.width = 260,
  });

  final CalendarEvent event;
  final double width;

  static String _fmt(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static const _kShadows = [
    Shadow(color: Colors.black54, offset: Offset(0, 1), blurRadius: 2),
  ];

  @override
  Widget build(BuildContext context) {
    final cleanDescription =
        event.description != null ? _stripHtml(event.description!) : null;
    final truncatedDescription =
        cleanDescription != null && cleanDescription.length > 200
            ? '${cleanDescription.substring(0, 197)}...'
            : cleanDescription;

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
            // Top Row: Category + Buttons
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.isTask
                        ? 'TASK:\n ${event.calendarName.toUpperCase()}'
                        : event.calendarName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10, // S5-FIX: Increased from 10
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: _kShadows,
                    ),
                  ),
                ),
                if (event.videoCallUrl != null) ...[
                  _LinkButton(
                    label: 'JOIN',
                    url: event.videoCallUrl!,
                    highlight: true,
                  ),
                  const SizedBox(width: 6),
                ],
                if (event.calendarEventUrl != null)
                  _LinkButton(
                    label: 'OPEN',
                    url: event.calendarEventUrl!,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // S5-FIX: Increased from 14
                fontWeight: FontWeight.w600,
                shadows: _kShadows,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmt(event.startTime)} – ${_fmt(event.endTime)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12, // S5-FIX: Increased from 12
                shadows: _kShadows,
              ),
            ),
            if (!event.isTask &&
                truncatedDescription != null &&
                truncatedDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                truncatedDescription,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12, // S5-FIX: Increased from 12
                  height: 1.3,
                  shadows: _kShadows,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: highlight ? Colors.white24 : Colors.white12,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: highlight ? Colors.white60 : Colors.white30,
          ),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10, // S5-FIX: Increased from 10
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                  color: Colors.black38, offset: Offset(0, 1), blurRadius: 1),
            ],
          ),
        ),
      ),
    );
  }
}
