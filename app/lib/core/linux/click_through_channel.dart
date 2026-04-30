abstract class ClickThroughChannel {
  Future<void> setPassThrough(bool enabled);
  Future<String> getDisplayServer();
  Future<bool> isLayerShellAvailable();
}

class NullClickThroughChannel implements ClickThroughChannel {
  const NullClickThroughChannel();

  @override
  Future<void> setPassThrough(bool enabled) async {}

  @override
  Future<String> getDisplayServer() async => 'unknown';

  @override
  Future<bool> isLayerShellAvailable() async => false;
}
