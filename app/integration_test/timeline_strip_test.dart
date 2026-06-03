import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:mockito/mockito.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

class _FakeWindowManager extends Mock implements WindowManager {}

class _FakeScreenRetriever extends Mock implements ScreenRetriever {}

class _FakeDisplayProbe extends Mock implements DisplayProbe {}

class _FakeDisplayEvents extends Mock implements DisplayEvents {}

class _FakeWindowService extends WindowService {
  _FakeWindowService()
      : super(
          windowManager: _FakeWindowManager(),
          screenRetriever: _FakeScreenRetriever(),
          displayService: DisplayService(
            probe: _FakeDisplayProbe(),
            events: _FakeDisplayEvents(),
          ),
        );

  Future<void> expand({double? height}) async {}

  Future<void> collapse({double? height}) async {}
}
