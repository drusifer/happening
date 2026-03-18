import 'package:flutter/material.dart';

/// Static canvas painting helpers shared across timeline layers.
class TimelinePaintUtils {
  static void paintText(
    Canvas canvas,
    String text,
    double x,
    double top, {
    required double fontSize,
    required Color color,
    required Color backgroundColor,
    bool centered = false,
  }) {
    final isDarkBg = ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;
    final List<Shadow>? shadows = isDarkBg
        ? [
            Shadow(
              blurRadius: 2.0,
              color: Colors.black.withValues(alpha: 0.5),
              offset: const Offset(0.5, 0.5),
            )
          ]
        : null;

    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        shadows: shadows,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();

    final finalX = centered ? x - painter.width / 2 : x;
    painter.paint(canvas, Offset(finalX, top));
  }

  static void paintEventLabel(
    Canvas canvas,
    String title,
    double x,
    double top,
    double maxWidth,
    double height, {
    required double fontSize,
    required Color backgroundColor,
    bool isTask = false,
  }) {
    final isDarkBg = ThemeData.estimateBrightnessForColor(backgroundColor) ==
        Brightness.dark;
    final textColor = isTask && !isDarkBg ? Colors.black87 : Colors.white;
    final shadow = (!isTask || isDarkBg)
        ? Shadow(
            blurRadius: 2.0,
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0.5, 0.5),
          )
        : null;

    final span = TextSpan(
      text: title,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        shadows: shadow != null ? [shadow] : null,
      ),
    );
    final painter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, top + height - painter.height - 4.0));
  }

  static void paintTaskMarker(
    Canvas canvas,
    double x,
    double endX,
    double cy,
    Color color, {
    required double fontSize,
  }) {
    final half = fontSize * 0.75;
    final diamondPath = Path();

    void addDiamond(double cx) {
      diamondPath.moveTo(cx, cy - half);
      diamondPath.lineTo(cx + half, cy);
      diamondPath.lineTo(cx, cy + half);
      diamondPath.lineTo(cx - half, cy);
      diamondPath.close();
    }

    addDiamond(x);
    final hasDuration = endX > x + 0.1;
    if (hasDuration) addDiamond(endX);

    const shadowOffset = Offset(1.5, 1.5);
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.45);

    if (hasDuration) {
      canvas.drawLine(
        Offset(x, cy) + shadowOffset,
        Offset(endX, cy) + shadowOffset,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.45)
          ..strokeWidth = 4.5,
      );
      canvas.drawLine(
        Offset(x, cy),
        Offset(endX, cy),
        Paint()
          ..color = color
          ..strokeWidth = 4.5,
      );
    }

    canvas.drawPath(
      Path()..addPath(diamondPath, shadowOffset),
      shadowPaint,
    );
    canvas.drawPath(diamondPath, Paint()..color = color);
    canvas.drawPath(
      diamondPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  static void paintHashFill(Canvas canvas, RRect rrect, Color color) {
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.25));

    final r = rrect.outerRect;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..strokeWidth = 1.5;

    const spacing = 5.0;
    final extent = r.width + r.height;
    for (var d = -r.height; d <= extent; d += spacing) {
      canvas.drawLine(
        Offset(r.left + d, r.top),
        Offset(r.left + d + r.height, r.bottom),
        linePaint,
      );
    }

    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0,
    );
  }
}
