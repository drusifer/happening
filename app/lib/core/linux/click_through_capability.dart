import 'click_through_channel.dart';

class ClickThroughCapability {
  const ClickThroughCapability({
    required this.supported,
    required this.displayServer,
  });

  final bool supported;
  final String displayServer;

  static const unsupported = ClickThroughCapability(
    supported: false,
    displayServer: 'unknown',
  );

  static Future<ClickThroughCapability> detect(ClickThroughChannel ch) async {
    final server = await ch.getDisplayServer();
    if (server != 'wayland') {
      return ClickThroughCapability(supported: false, displayServer: server);
    }
    final hasShell = await ch.isLayerShellAvailable();
    return ClickThroughCapability(supported: hasShell, displayServer: server);
  }
}
