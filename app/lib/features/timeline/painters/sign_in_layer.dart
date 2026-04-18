import 'package:flutter/material.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';

/// TLDR: Paints a "Tap to sign in with Google →" overlay when the user is
/// unauthenticated. No-ops once isSignIn is false so the compositor loop is
/// unconditional.
class SignInLayer implements TimelineLayer {
  const SignInLayer({
    required this.isSignIn,
    required this.isSigningIn,
    required this.backgroundColor,
    required this.textColor,
    required this.fontSize,
  });

  final bool isSignIn;
  final bool isSigningIn;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (!isSignIn) return;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = backgroundColor,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: isSigningIn
            ? 'Signing in… tap to cancel'
            : 'Tap to sign in with Google →',
        style: TextStyle(
          color: textColor.withValues(alpha: 0.7),
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);

    tp.paint(
      canvas,
      Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
    );
  }
}
