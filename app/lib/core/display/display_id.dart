// Typed identifier for a connected display.
//
// TLDR:
// Overview: Wraps screen_retriever's Display.id String in a typed value.
// Problem:  Bare String IDs leak across persistence and matching code paths.
// Solution: DisplayId value object with equality + hashCode + toString.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

@immutable
class DisplayId {
  const DisplayId(this.value);
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is DisplayId && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DisplayId($value)';
}
