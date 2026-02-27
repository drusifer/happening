/// End-of-day celebration UI.
///
/// TLDR:
/// Overview: Displays a "You're free!" message when no more events remain.
/// Problem: Need to provide positive feedback and a clear state for an empty timeline.
/// Solution: Implements a simple, centered widget with emojis and a dark background.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';

/// Shown when there are no more events left today.
class CelebrationWidget extends StatelessWidget {
  const CelebrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A2E),
      alignment: Alignment.center,
      child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('🎉', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text(
          "You're free! No more events today.",
          style: TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(width: 8),
        Text('🎉', style: TextStyle(fontSize: 18)),
      ],
    ),
    );
  }
}
