import 'package:flutter/foundation.dart';

/// Confirmed physical window state emitted after GTK acknowledges a resize.
///
/// TLDR:
/// Overview: Immutable value type representing the OS window's actual dimensions.
/// Problem: Card rendering raced with GTK resize; this type is only emitted post-confirmation.
/// Solution: ExpansionController emits PhysicalWindowState after resize() completes.
/// Breaking Changes: No.
@immutable
class PhysicalWindowState {
  const PhysicalWindowState({required this.height, required this.isExpanded});

  /// Sentinel for the pre-first-resize state; used as StreamBuilder initialData.
  static const collapsed = PhysicalWindowState(height: 0, isExpanded: false);

  final double height;
  final bool isExpanded;

  @override
  bool operator ==(Object other) =>
      other is PhysicalWindowState &&
      other.height == height &&
      other.isExpanded == isExpanded;

  @override
  int get hashCode => Object.hash(height, isExpanded);

  @override
  String toString() =>
      'PhysicalWindowState(height=$height, isExpanded=$isExpanded)';
}
