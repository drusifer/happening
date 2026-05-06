import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/linux/click_through_capability.dart';
import 'package:happening/core/linux/click_through_channel.dart';

class _FakeClickThroughChannel implements ClickThroughChannel {
  const _FakeClickThroughChannel({
    required this.displayServer,
    required this.supported,
  });

  final String displayServer;
  final bool supported;

  @override
  Future<String> getDisplayServer() async => displayServer;

  @override
  Future<bool> isClickThroughAvailable() async => supported;

  @override
  Future<void> setPassThrough(bool enabled) async {}
}

void main() {
  test('detect rejects X11 even when native channel reports support', () async {
    final capability = await ClickThroughCapability.detect(
      const _FakeClickThroughChannel(
        displayServer: 'x11',
        supported: true,
      ),
    );

    expect(capability.displayServer, 'x11');
    expect(capability.supported, isFalse);
  });

  test('detect allows XWayland when native channel reports support', () async {
    final capability = await ClickThroughCapability.detect(
      const _FakeClickThroughChannel(
        displayServer: 'xwayland',
        supported: true,
      ),
    );

    expect(capability.displayServer, 'xwayland');
    expect(capability.supported, isTrue);
  });

  test('detect rejects Wayland even when native channel reports support',
      () async {
    final capability = await ClickThroughCapability.detect(
      const _FakeClickThroughChannel(
        displayServer: 'wayland',
        supported: true,
      ),
    );

    expect(capability.displayServer, 'wayland');
    expect(capability.supported, isFalse);
  });

  test('detect still respects unsupported native channel result', () async {
    final capability = await ClickThroughCapability.detect(
      const _FakeClickThroughChannel(
        displayServer: 'unknown',
        supported: false,
      ),
    );

    expect(capability.displayServer, 'unknown');
    expect(capability.supported, isFalse);
  });
}
