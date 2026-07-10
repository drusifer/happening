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
    final style = _HoverCardStyle.forEvent(event, fontSize: fontSize);
    final cleanDescription =
        event.description != null ? _stripHtml(event.description!) : null;
    final truncatedDescription =
        cleanDescription != null && cleanDescription.length > 200
            ? '${cleanDescription.substring(0, 197)}...'
            : cleanDescription;

    // Clips the card's own boxShadow above its top edge — that edge attaches
    // directly to the event block, so a shadow bleeding upward there would
    // look like a seam instead of one continuous shape. Left/right/bottom
    // overflow (where the shadow actually reads as a shadow) is untouched.
    return ClipRect(
      clipper: const _NoTopShadowClipper(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          decoration: BoxDecoration(
            // Fully opaque, matching the event block's own color exactly (the
            // block also renders fully opaque while this card is open — see
            // EventsLayer.cardOpenEventId) so the two read as one shape.
            color: style.color,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
              bottomRight: Radius.circular(6),
            ),
            // No top border — it attaches directly to the event block above,
            // which omits its own bottom border for the same reason. Left/
            // right/bottom continue the block's border style around the card.
            border: Border(
              left: BorderSide(color: style.borderColor),
              right: BorderSide(color: style.borderColor),
              bottom: BorderSide(color: style.borderColor),
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
              _buildHeaderRow(style),
              const SizedBox(height: 6),
              Text(
                event.title,
                style: TextStyle(
                  color: style.textPrimary,
                  fontSize: style.titleSize,
                  fontWeight: FontWeight.w600,
                  shadows: style.shadows,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_fmt(context, event.startTime)} – ${_fmt(context, event.endTime)}',
                style: TextStyle(
                  color: style.textSecondary,
                  fontSize: style.bodySize,
                  shadows: style.shadows,
                ),
              ),
              ..._buildDescription(truncatedDescription, style),
            ],
          ),
        ),
      ),
    );
  }

  /// Top row: category label (left) + JOIN/OPEN link buttons (right).
  Widget _buildHeaderRow(_HoverCardStyle style) {
    return Row(
      children: [
        Expanded(
          child: Text(
            event.isTask
                ? 'TASK:\n ${event.calendarName.toUpperCase()}'
                : event.calendarName.toUpperCase(),
            style: TextStyle(
              color: style.textMuted,
              fontSize: style.labelSize,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: style.shadows,
            ),
          ),
        ),
        if (event.videoCallUrl != null) ...[
          _LinkButton(
            label: 'JOIN',
            url: event.videoCallUrl!,
            fontSize: style.labelSize,
            highlight: true,
            isLight: style.isLight,
          ),
          const SizedBox(width: 6),
        ],
        if (event.calendarEventUrl != null)
          _LinkButton(
            label: 'OPEN',
            url: event.calendarEventUrl!,
            fontSize: style.labelSize,
            isLight: style.isLight,
          ),
      ],
    );
  }

  /// The truncated description text, or nothing for tasks / empty descriptions.
  List<Widget> _buildDescription(
      String? truncatedDescription, _HoverCardStyle style) {
    if (event.isTask ||
        truncatedDescription == null ||
        truncatedDescription.isEmpty) {
      return const [];
    }
    return [
      const SizedBox(height: 8),
      Text(
        truncatedDescription,
        style: TextStyle(
          color: style.textPrimary,
          fontSize: style.bodySize,
          height: 1.3,
          shadows: style.shadows,
        ),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    ];
  }
}

/// Derived colors/sizes for one [HoverDetailOverlay], computed once from the
/// event's display color + card font size.
@immutable
class _HoverCardStyle {
  const _HoverCardStyle({
    required this.color,
    required this.isLight,
    required this.labelSize,
    required this.titleSize,
    required this.bodySize,
    required this.shadows,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderColor,
  });

  factory _HoverCardStyle.forEvent(CalendarEvent event,
      {required double fontSize}) {
    final color = event.displayColor;
    final isLight = color.computeLuminance() > 0.4;
    return _HoverCardStyle(
      color: color,
      isLight: isLight,
      labelSize: fontSize * 0.67,
      titleSize: fontSize * 0.93,
      bodySize: fontSize * 0.80,
      shadows: [
        Shadow(
          color: isLight ? const Color(0x22FFFFFF) : Colors.black54,
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      textPrimary: isLight ? const Color(0xDD000000) : Colors.white,
      textSecondary: isLight ? const Color(0x99000000) : Colors.white70,
      textMuted: isLight ? const Color(0x77000000) : Colors.white60,
      borderColor: Color.lerp(color, Colors.black, 0.4)!,
    );
  }

  final Color color;
  final bool isLight;
  final double labelSize;
  final double titleSize;
  final double bodySize;
  final List<Shadow> shadows;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderColor;
}

/// Clips the card's own boxShadow above its top edge and left of its left
/// edge — see the comment where this is used in [HoverDetailOverlay.build].
/// Leaves the right/bottom shadow untouched, consistent with a light source
/// from the upper-left (shadows fall down and to the right).
class _NoTopShadowClipper extends CustomClipper<Rect> {
  const _NoTopShadowClipper();

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width + 100, size.height + 100);

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
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
        ? (highlight ? const Color(0x33000000) : const Color(0x1A000000))
        : (highlight ? Colors.white24 : Colors.white12);
    final borderColor = isLight
        ? (highlight ? const Color(0x99000000) : const Color(0x4D000000))
        : (highlight ? Colors.white60 : Colors.white30);
    final textColor = isLight ? const Color(0xDD000000) : Colors.white;

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
