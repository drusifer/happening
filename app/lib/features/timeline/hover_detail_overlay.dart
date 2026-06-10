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
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/features/calendar/calendar_event.dart';
import 'package:url_launcher/url_launcher.dart';

/// Card that expands downward from an event block on hover.
class HoverDetailOverlay extends StatelessWidget {
  const HoverDetailOverlay({
    super.key,
    required this.event,
    this.width = 260,
    this.fontSize = kDefaultFontSizePx,
  });

  final CalendarEvent event;
  final double width;
  final double fontSize;

  String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>|&nbsp;'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _fmt(BuildContext context, DateTime t) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(t),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cleanDescription =
        event.description != null ? _stripHtml(event.description!) : null;
    final truncatedDescription =
        cleanDescription != null && cleanDescription.length > 200
            ? '${cleanDescription.substring(0, 197)}...'
            : cleanDescription;

    final labelSize = fontSize * 0.67;
    final titleSize = fontSize * 0.93;
    final bodySize = fontSize * 0.80;

    final isLight = event.color.computeLuminance() > 0.4;
    final kShadows = [
      Shadow(
        color: isLight ? const Color(0x22FFFFFF) : Colors.black54,
        offset: const Offset(0, 1),
        blurRadius: 2,
      ),
    ];
    final textPrimary = isLight ? const Color(0xDD000000) : Colors.white;
    final textSecondary =
        isLight ? const Color(0x99000000) : Colors.white70;
    final textMuted = isLight ? const Color(0x77000000) : Colors.white60;

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
                    style: TextStyle(
                      color: textMuted,
                      fontSize: labelSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: kShadows,
                    ),
                  ),
                ),
                if (event.videoCallUrl != null) ...[
                  _LinkButton(
                    label: 'JOIN',
                    url: event.videoCallUrl!,
                    fontSize: labelSize,
                    highlight: true,
                    isLight: isLight,
                  ),
                  const SizedBox(width: 6),
                ],
                if (event.calendarEventUrl != null)
                  _LinkButton(
                    label: 'OPEN',
                    url: event.calendarEventUrl!,
                    fontSize: labelSize,
                    isLight: isLight,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              event.title,
              style: TextStyle(
                color: textPrimary,
                fontSize: titleSize,
                fontWeight: FontWeight.w600,
                shadows: kShadows,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_fmt(context, event.startTime)} – ${_fmt(context, event.endTime)}',
              style: TextStyle(
                color: textSecondary,
                fontSize: bodySize,
                shadows: kShadows,
              ),
            ),
            if (!event.isTask &&
                truncatedDescription != null &&
                truncatedDescription.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                truncatedDescription,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: bodySize,
                  height: 1.3,
                  shadows: kShadows,
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
    required this.fontSize,
    this.highlight = false,
    this.isLight = false,
  });

  final String label;
  final String url;
  final double fontSize;
  final bool highlight;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final bgColor = isLight
        ? (highlight
            ? const Color(0x33000000)
            : const Color(0x1A000000))
        : (highlight ? Colors.white24 : Colors.white12);
    final borderColor = isLight
        ? (highlight
            ? const Color(0x99000000)
            : const Color(0x4D000000))
        : (highlight ? Colors.white60 : Colors.white30);
    final textColor =
        isLight ? const Color(0xDD000000) : Colors.white;

    return GestureDetector(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
                color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
