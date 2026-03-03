class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
        );

  @override
  bool get isExpanded => false;

  @override
  Future<void> expand({double? height}) async {}

  @override
  Future<void> collapse({double? height}) async {}
}
