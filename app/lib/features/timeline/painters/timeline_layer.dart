import 'package:flutter/material.dart';

/// Interface for a single painter layer in the timeline.
abstract class TimelineLayer {
  void paint(Canvas canvas, Size size);
}
