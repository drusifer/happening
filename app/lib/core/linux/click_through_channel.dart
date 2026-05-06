abstract class ClickThroughChannel {
  Future<void> setPassThrough(bool enabled);
  Future<String> getDisplayServer();
  Future<bool> isClickThroughAvailable();
}

class NullClickThroughChannel implements ClickThroughChannel {
  const NullClickThroughChannel();

  @override
  Future<void> setPassThrough(bool enabled) async {}

  @override
  Future<String> getDisplayServer() async => 'unknown';

  @override
  Future<bool> isClickThroughAvailable() async => false;
}
