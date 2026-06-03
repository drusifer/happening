import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/display/display_id.dart';
import 'package:happening/core/display/display_info.dart';
import 'package:happening/core/display/persisted_display_choice.dart';

DisplayInfo _d({
  required String id,
  String? name,
  double width = 1920,
  double height = 1080,
  double originX = 0,
  double originY = 0,
  bool primary = false,
}) {
  return DisplayInfo(
    id: DisplayId(id),
    osName: name,
    size: Size(width, height),
    workAreaOrigin: Offset(originX, originY),
    workAreaSize: Size(width, height),
    scaleFactor: 1.0,
    isPrimary: primary,
  );
}

void main() {
  group('PersistedDisplayChoice.fromDisplay', () {
    test('captures osName, size, and position', () {
      final d = _d(id: 'a', name: 'Dell U2723QE', originX: 1920);
      final choice = PersistedDisplayChoice.fromDisplay(d);
      expect(choice.osName, 'Dell U2723QE');
      expect(choice.widthLogical, 1920);
      expect(choice.heightLogical, 1080);
      expect(choice.xOffsetLogical, 1920);
      expect(choice.yOffsetLogical, 0);
    });

    test('null osName becomes empty string', () {
      final d = _d(id: 'a', name: null);
      final choice = PersistedDisplayChoice.fromDisplay(d);
      expect(choice.osName, '');
    });
  });

  group('PersistedDisplayChoice.matchIn — exact', () {
    test('all fields match → exact', () {
      final d = _d(id: 'a', name: 'Dell U2723QE', originX: 1920);
      final choice = PersistedDisplayChoice.fromDisplay(d);
      final match = choice.matchIn([d])!;
      expect(match.display, d);
      expect(match.strength, PersistedDisplayChoiceMatchStrength.exact);
    });
  });

  group('PersistedDisplayChoice.matchIn — strong', () {
    test('same name+size, different position → strong', () {
      final original = _d(id: 'a', name: 'Dell U2723QE', originX: 1920);
      final moved = _d(id: 'a', name: 'Dell U2723QE', originX: 3840);
      final choice = PersistedDisplayChoice.fromDisplay(original);
      final match = choice.matchIn([moved])!;
      expect(match.display, moved);
      expect(match.strength, PersistedDisplayChoiceMatchStrength.strong);
    });

    test('exact wins over strong when both available', () {
      final exact = _d(id: 'a', name: 'Dell U2723QE', originX: 1920);
      final strong = _d(id: 'b', name: 'Dell U2723QE', originX: 3840);
      final choice = PersistedDisplayChoice.fromDisplay(exact);
      final match = choice.matchIn([strong, exact])!;
      expect(match.display, exact);
      expect(match.strength, PersistedDisplayChoiceMatchStrength.exact);
    });
  });

  group('PersistedDisplayChoice.matchIn — weak', () {
    test('same name, different size → weak', () {
      final original =
          _d(id: 'a', name: 'Dell U2723QE', width: 3840, height: 2160);
      final different =
          _d(id: 'a', name: 'Dell U2723QE', width: 1920, height: 1080);
      final choice = PersistedDisplayChoice.fromDisplay(original);
      final match = choice.matchIn([different])!;
      expect(match.display, different);
      expect(match.strength, PersistedDisplayChoiceMatchStrength.weak);
    });

    test('strong wins over weak when both available', () {
      final strong = _d(id: 'a', name: 'X', width: 1920, originX: 3840);
      final weak = _d(id: 'b', name: 'X', width: 1280, originX: 0);
      final origin = _d(id: 'orig', name: 'X', width: 1920);
      final choice = PersistedDisplayChoice.fromDisplay(origin);
      final match = choice.matchIn([weak, strong])!;
      expect(match.strength, PersistedDisplayChoiceMatchStrength.strong);
      expect(match.display, strong);
    });
  });

  group('PersistedDisplayChoice.matchIn — no match', () {
    test('no display with same name → null', () {
      final origin = _d(id: 'orig', name: 'Dell U2723QE');
      final unrelated = _d(id: 'x', name: 'ASUS PA32UCX');
      final choice = PersistedDisplayChoice.fromDisplay(origin);
      expect(choice.matchIn([unrelated]), isNull);
    });

    test('empty available list → null', () {
      final origin = _d(id: 'orig', name: 'Dell U2723QE');
      final choice = PersistedDisplayChoice.fromDisplay(origin);
      expect(choice.matchIn(const []), isNull);
    });
  });

  group('PersistedDisplayChoice JSON', () {
    test('toJson + fromJson roundtrip', () {
      const original = PersistedDisplayChoice(
        osName: 'Dell U2723QE',
        widthLogical: 3840,
        heightLogical: 2160,
        xOffsetLogical: 1920,
        yOffsetLogical: 100,
      );
      final restored = PersistedDisplayChoice.fromJson(original.toJson());
      expect(restored, original);
    });

    test('fromJson missing fields → safe defaults', () {
      final restored = PersistedDisplayChoice.fromJson({});
      expect(restored.osName, '');
      expect(restored.widthLogical, 0);
      expect(restored.heightLogical, 0);
      expect(restored.xOffsetLogical, 0);
      expect(restored.yOffsetLogical, 0);
    });
  });

  group('PersistedDisplayChoice equality', () {
    test('same fields → equal + same hash', () {
      const a = PersistedDisplayChoice(
        osName: 'X',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      const b = PersistedDisplayChoice(
        osName: 'X',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('different name → not equal', () {
      const a = PersistedDisplayChoice(
        osName: 'X',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      const b = PersistedDisplayChoice(
        osName: 'Y',
        widthLogical: 1920,
        heightLogical: 1080,
        xOffsetLogical: 0,
        yOffsetLogical: 0,
      );
      expect(a, isNot(b));
    });
  });
}
