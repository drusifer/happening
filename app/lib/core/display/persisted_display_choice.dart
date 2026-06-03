// User's persisted display preference as a composite fingerprint.
//
// TLDR:
// Overview: Survives the user's "I always want display X" choice across app
//           restarts even when screen_retriever's raw Display.id changes
//           between sessions.
// Problem:  Display.id stability is platform-dependent; persisting raw IDs
//           breaks every reboot on some hosts.
// Solution: Composite fingerprint (osName + size + position) with a 3-tier
//           match algorithm — exact / strong / weak — implementing the
//           identity scheme defined in the F-30 arch doc.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/foundation.dart';

import 'display_info.dart';

/// Indicates how strongly a [PersistedDisplayChoice] matched a current
/// [DisplayInfo].
enum PersistedDisplayChoiceMatchStrength {
  /// Same osName, same size, same position. The user's display is back
  /// in the same spot.
  exact,

  /// Same osName, same size, position changed. Likely the user rearranged
  /// their multi-monitor layout but the same physical display is connected.
  strong,

  /// Same osName only. May be a different monitor of the same model — the
  /// service logs a warning when this happens.
  weak,
}

class PersistedDisplayChoiceMatch {
  const PersistedDisplayChoiceMatch(this.display, this.strength);
  final DisplayInfo display;
  final PersistedDisplayChoiceMatchStrength strength;
}

@immutable
class PersistedDisplayChoice {
  const PersistedDisplayChoice({
    required this.osName,
    required this.widthLogical,
    required this.heightLogical,
    required this.xOffsetLogical,
    required this.yOffsetLogical,
  });

  /// Constructs a fingerprint from a currently-available display. Use this
  /// when the user picks a display in Settings.
  factory PersistedDisplayChoice.fromDisplay(DisplayInfo d) {
    return PersistedDisplayChoice(
      osName: d.osName ?? '',
      widthLogical: d.size.width,
      heightLogical: d.size.height,
      xOffsetLogical: d.workAreaOrigin.dx,
      yOffsetLogical: d.workAreaOrigin.dy,
    );
  }

  final String osName;
  final double widthLogical;
  final double heightLogical;
  final double xOffsetLogical;
  final double yOffsetLogical;

  /// Resolves this persisted choice against the currently-available displays,
  /// trying exact → strong → weak match in order. Returns null when no
  /// display has the same osName.
  PersistedDisplayChoiceMatch? matchIn(List<DisplayInfo> available) {
    DisplayInfo? exact;
    DisplayInfo? strong;
    DisplayInfo? weak;

    for (final d in available) {
      final dName = d.osName ?? '';
      if (dName != osName) continue;
      weak ??= d;

      final sameSize =
          d.size.width == widthLogical && d.size.height == heightLogical;
      if (!sameSize) continue;
      strong ??= d;

      final samePosition = d.workAreaOrigin.dx == xOffsetLogical &&
          d.workAreaOrigin.dy == yOffsetLogical;
      if (samePosition) {
        exact ??= d;
        break;
      }
    }

    if (exact != null) {
      return PersistedDisplayChoiceMatch(
        exact,
        PersistedDisplayChoiceMatchStrength.exact,
      );
    }
    if (strong != null) {
      return PersistedDisplayChoiceMatch(
        strong,
        PersistedDisplayChoiceMatchStrength.strong,
      );
    }
    if (weak != null) {
      return PersistedDisplayChoiceMatch(
        weak,
        PersistedDisplayChoiceMatchStrength.weak,
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'osName': osName,
        'widthLogical': widthLogical,
        'heightLogical': heightLogical,
        'xOffsetLogical': xOffsetLogical,
        'yOffsetLogical': yOffsetLogical,
      };

  factory PersistedDisplayChoice.fromJson(Map<String, dynamic> json) {
    return PersistedDisplayChoice(
      osName: json['osName'] as String? ?? '',
      widthLogical: (json['widthLogical'] as num? ?? 0).toDouble(),
      heightLogical: (json['heightLogical'] as num? ?? 0).toDouble(),
      xOffsetLogical: (json['xOffsetLogical'] as num? ?? 0).toDouble(),
      yOffsetLogical: (json['yOffsetLogical'] as num? ?? 0).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersistedDisplayChoice &&
          other.osName == osName &&
          other.widthLogical == widthLogical &&
          other.heightLogical == heightLogical &&
          other.xOffsetLogical == xOffsetLogical &&
          other.yOffsetLogical == yOffsetLogical);

  @override
  int get hashCode => Object.hash(
        osName,
        widthLogical,
        heightLogical,
        xOffsetLogical,
        yOffsetLogical,
      );

  @override
  String toString() =>
      'PersistedDisplayChoice(osName=$osName, size=${widthLogical}x$heightLogical, '
      'offset=($xOffsetLogical,$yOffsetLogical))';
}
