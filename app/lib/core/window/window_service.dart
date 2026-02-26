import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const double _kStripHeightLogical = 52.0;

/// Configures the app window as an always-on-top frameless strip.
class WindowService {
  /// Call once, before [runApp], to set up the window.
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();

    final display = await screenRetriever.getPrimaryDisplay();
    final screenWidth = display.visibleSize?.width ?? 1920.0;

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: Size(screenWidth, _kStripHeightLogical),
        backgroundColor: const Color(0x00000000),
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
        windowButtonVisibility: false,
      ),
      () async {
        await windowManager.setPosition(Offset.zero);
        await windowManager.setResizable(false);
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }
}
