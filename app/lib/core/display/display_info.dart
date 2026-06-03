// Per-display geometry, scale, and user-facing label resolution.
//
// TLDR:
// Overview: Immutable view of one connected display with a labelFor() chain.
// Problem:  OS-reported display names are often empty/generic/duplicate; raw
//           Display.id is not user-meaningful.
// Solution: DisplayInfo carries geometry + scale; labelFor() resolves a
//           unique, human-readable label per F-30 stories (Smith Gate 1
//           Note 2): OS name when non-empty + non-generic + unique; else
//           "Display N — WxH". Primary always carries " — primary".
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'display_id.dart';

const Set<String> _genericDisplayNames = {
  'Generic PnP Monitor',
  'Unknown Display',
  'Default Monitor',
  'Display',
  'Built-in Display',
};

final RegExp _connectorNameRegex = RegExp(
  r'^(eDP|DP|HDMI|VGA|DVI|LVDS|Virtual|Composite|S-Video|TV|DVI-[I|D|A])[0-9-]*$',
  caseSensitive: false,
);

@immutable
class DisplayInfo {
  const DisplayInfo({
    required this.id,
    required this.osName,
    required this.size,
    required this.workAreaOrigin,
    required this.workAreaSize,
    required this.scaleFactor,
    required this.isPrimary,
  });

  final DisplayId id;
  final String? osName;
  final Size size;
  final Offset workAreaOrigin;
  final Size workAreaSize;
  final double scaleFactor;
  final bool isPrimary;

  /// Returns a stable, user-facing label for this display, choosing between
  /// the OS-reported name and a numeric fallback.
  ///
  /// Rules (Smith Gate 1 Note 2):
  ///  1. If [osName] is non-empty, not in [_genericDisplayNames], not matching
  ///     [_connectorNameRegex], and unique across [all] → use the OS name.
  ///  2. Otherwise → use "Display N — WxH" where N is the 1-based position of
  ///     this display in [all] sorted by (workAreaOrigin.dx, workAreaOrigin.dy).
  ///  3. The primary display always carries a " — primary" suffix in either
  ///     form.
  String labelFor(List<DisplayInfo> all) {
    final primarySuffix = isPrimary ? ' — primary' : '';

    final trimmed = osName?.trim() ?? '';
    final hasUsableOsName = trimmed.isNotEmpty &&
        !_genericDisplayNames.contains(trimmed) &&
        !_connectorNameRegex.hasMatch(trimmed);

    if (hasUsableOsName) {
      final duplicates =
          all.where((d) => (d.osName?.trim() ?? '') == trimmed).length;
      if (duplicates == 1) {
        return '$trimmed$primarySuffix';
      }
    }

    final sorted = [...all]..sort((a, b) {
        final dx = a.workAreaOrigin.dx.compareTo(b.workAreaOrigin.dx);
        if (dx != 0) return dx;
        return a.workAreaOrigin.dy.compareTo(b.workAreaOrigin.dy);
      });

    final fallbackDisplays = sorted.where((d) {
      final dTrimmed = d.osName?.trim() ?? '';
      final dHasUsable = dTrimmed.isNotEmpty &&
          !_genericDisplayNames.contains(dTrimmed) &&
          !_connectorNameRegex.hasMatch(dTrimmed);
      if (!dHasUsable) return true;
      final dDuplicates =
          all.where((x) => (x.osName?.trim() ?? '') == dTrimmed).length;
      return dDuplicates > 1;
    }).toList();

    final idx = fallbackDisplays.indexWhere((d) => d == this);
    final indexNumber = idx >= 0 ? idx + 1 : 1;

    final w = size.width.toInt();
    final h = size.height.toInt();
    return 'Display $indexNumber — $w×$h$primarySuffix';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DisplayInfo &&
          other.id == id &&
          other.osName == osName &&
          other.size == size &&
          other.workAreaOrigin == workAreaOrigin &&
          other.workAreaSize == workAreaSize &&
          other.scaleFactor == scaleFactor &&
          other.isPrimary == isPrimary);

  @override
  int get hashCode => Object.hash(
        id,
        osName,
        size,
        workAreaOrigin,
        workAreaSize,
        scaleFactor,
        isPrimary,
      );

  @override
  String toString() => 'DisplayInfo(id=$id, osName=$osName, size=$size, '
      'workArea=($workAreaOrigin, $workAreaSize), '
      'scale=$scaleFactor, primary=$isPrimary)';
}
