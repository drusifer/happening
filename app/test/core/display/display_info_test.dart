import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';

DisplayInfo _d({
  required String id,
  String? name,
  double width = 1920,
  double height = 1080,
  double originX = 0,
  double originY = 0,
  double scale = 1.0,
  bool primary = false,
}) {
  return DisplayInfo(
    id: DisplayId(id),
    osName: name,
    size: Size(width, height),
    workAreaOrigin: Offset(originX, originY),
    workAreaSize: Size(width, height),
    scaleFactor: scale,
    isPrimary: primary,
  );
}

void main() {
  group('DisplayInfo.labelFor — OS-name path', () {
    test('non-empty, non-generic, unique OS name is used', () {
      final a = _d(id: 'a', name: 'Dell U2723QE', primary: true);
      final b = _d(id: 'b', name: 'ASUS PA32UCX', originX: 3840);
      expect(a.labelFor([a, b]), 'Dell U2723QE — primary');
      expect(b.labelFor([a, b]), 'ASUS PA32UCX');
    });

    test('OS name is trimmed before comparison', () {
      final a = _d(id: 'a', name: '  Dell U2723QE  ', primary: true);
      expect(a.labelFor([a]), 'Dell U2723QE — primary');
    });
  });

  group('DisplayInfo.labelFor — numeric fallback path', () {
    test('empty OS name falls back to "Display N — WxH"', () {
      final a = _d(id: 'a', name: '', primary: true);
      final b =
          _d(id: 'b', name: null, originX: 1920, width: 1280, height: 800);
      expect(a.labelFor([a, b]), 'Display 1 — 1920×1080 — primary');
      expect(b.labelFor([a, b]), 'Display 2 — 1280×800');
    });

    test('null OS name falls back to numeric label', () {
      final a = _d(id: 'a', name: null, primary: true);
      expect(a.labelFor([a]), 'Display 1 — 1920×1080 — primary');
    });

    test('generic OS names fall back to numeric label', () {
      for (final generic in const [
        'Generic PnP Monitor',
        'Unknown Display',
        'Default Monitor',
        'Display',
        'Built-in Display',
      ]) {
        final a = _d(id: 'a', name: generic, primary: true);
        expect(
          a.labelFor([a]),
          'Display 1 — 1920×1080 — primary',
          reason: 'Expected $generic to fall back',
        );
      }
    });

    test('connector names fall back to numeric label', () {
      for (final conn in const [
        'eDP-1',
        'DP-3',
        'HDMI-1',
        'VGA-1',
        'HDMI1',
        'dp2',
      ]) {
        final a = _d(id: 'a', name: conn, primary: true);
        expect(
          a.labelFor([a]),
          'Display 1 — 1920×1080 — primary',
          reason: 'Expected connector name $conn to fall back',
        );
      }
    });

    test('Windows GDI device paths fall back to numeric label', () {
      for (final gdi in const [
        r'\\.\DISPLAY1',
        r'\\.\DISPLAY2',
        r'\\.\DISPLAY1\Monitor0',
      ]) {
        final a = _d(id: 'a', name: gdi, primary: true);
        expect(
          a.labelFor([a]),
          'Display 1 — 1920×1080 — primary',
          reason: 'Expected GDI device path $gdi to fall back',
        );
      }
    });

    test('duplicate OS names fall back to numeric label for both', () {
      final a = _d(id: 'a', name: 'Dell U2723QE', primary: true);
      final b = _d(id: 'b', name: 'Dell U2723QE', originX: 3840);
      expect(a.labelFor([a, b]), 'Display 1 — 1920×1080 — primary');
      expect(b.labelFor([a, b]), 'Display 2 — 1920×1080');
    });

    test('duplicate/generic display IDs resolve to distinct numeric labels',
        () {
      final a = _d(id: '0', name: 'eDP-1', primary: true);
      final b = _d(id: '0', name: 'DP-3', originX: 1920);
      expect(a.labelFor([a, b]), 'Display 1 — 1920×1080 — primary');
      expect(b.labelFor([a, b]), 'Display 2 — 1920×1080');
    });
  });

  group('DisplayInfo.labelFor — primary suffix', () {
    test('primary suffix applied in OS-name form', () {
      final a = _d(id: 'a', name: 'Dell U2723QE', primary: true);
      final b = _d(id: 'b', name: 'ASUS PA32UCX', originX: 3840);
      expect(a.labelFor([a, b]).endsWith(' — primary'), isTrue);
      expect(b.labelFor([a, b]).endsWith(' — primary'), isFalse);
    });

    test('primary suffix applied in numeric form', () {
      final a = _d(id: 'a', name: null, primary: true);
      expect(a.labelFor([a]).endsWith(' — primary'), isTrue);
    });
  });

  group('DisplayInfo.labelFor — stable index ordering', () {
    test('leftmost display is Display 1 regardless of list order', () {
      final left = _d(id: 'left', name: null, originX: 0);
      final right = _d(id: 'right', name: null, originX: 1920);

      final orderedA = [left, right];
      final orderedB = [right, left];

      expect(left.labelFor(orderedA).startsWith('Display 1'), isTrue);
      expect(left.labelFor(orderedB).startsWith('Display 1'), isTrue);
      expect(right.labelFor(orderedA).startsWith('Display 2'), isTrue);
      expect(right.labelFor(orderedB).startsWith('Display 2'), isTrue);
    });

    test('tie-breaks by y when x is equal', () {
      final top = _d(id: 'top', name: null, originX: 0, originY: 0);
      final bottom = _d(id: 'bot', name: null, originX: 0, originY: 1080);
      expect(top.labelFor([top, bottom]).startsWith('Display 1'), isTrue);
      expect(bottom.labelFor([top, bottom]).startsWith('Display 2'), isTrue);
    });

    test('mixed usable and fallback displays numbers fallback correctly', () {
      final left = _d(id: 'left', name: 'Dell U2723QE', originX: 0);
      final mid = _d(id: 'mid', name: null, originX: 3840);
      final right = _d(id: 'right', name: 'HDMI-1', originX: 5760);

      final all = [left, mid, right];
      expect(left.labelFor(all), 'Dell U2723QE');
      expect(mid.labelFor(all), 'Display 1 — 1920×1080');
      expect(right.labelFor(all), 'Display 2 — 1920×1080');
    });
  });

  group('DisplayInfo equality', () {
    test('same fields → equal', () {
      final a = _d(id: 'a', name: 'X', primary: true);
      final b = _d(id: 'a', name: 'X', primary: true);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different id → not equal', () {
      final a = _d(id: 'a', name: 'X');
      final b = _d(id: 'b', name: 'X');
      expect(a, isNot(b));
    });
  });
}
