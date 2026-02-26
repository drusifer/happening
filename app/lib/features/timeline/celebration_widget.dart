import 'package:flutter/material.dart';

/// Shown when there are no more events left today.
class CelebrationWidget extends StatelessWidget {
  const CelebrationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
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
    );
  }
}
