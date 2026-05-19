import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/window/linux_dock_window_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('linux_dock_window_manager');
  final log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      log.add(call);
      switch (call.method) {
        case 'isDockable':
          return true;
        case 'dock':
          return null;
        case 'undock':
          return null;
        default:
          throw PlatformException(code: 'NOT_IMPLEMENTED');
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isDockable returns value from channel', () async {
    final manager = LinuxDockWindowManager();
    expect(await manager.isDockable(), isTrue);
    expect(log.single.method, 'isDockable');
  });

  test('dock sends height argument', () async {
    final manager = LinuxDockWindowManager();
    await manager.dock(height: 55);
    expect(log.single.method, 'dock');
    expect(log.single.arguments['height'], 55);
  });

  test('dock sends physical pixel height', () async {
    final manager = LinuxDockWindowManager();
    await manager.dock(height: 110);
    expect(log.single.arguments['height'], 110);
  });

  test('undock sends undock method', () async {
    final manager = LinuxDockWindowManager();
    await manager.undock();
    expect(log.single.method, 'undock');
  });
}
