import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

const double _kStripHeightLogical = 36.0;

/// Configures the app window as an always-on-top frameless strip.
class WindowService {
  /// Call once, before [runApp], to set up the window.
  static Future<void> initialize() async {
    await windowManager.ensureInitialized();

    final display = await screenRetriever.getPrimaryDisplay();

    // screen_retriever returns physical pixels on Linux HiDPI displays.
    // Divide by devicePixelRatio to get logical pixels for window_manager.
    final dpr = display.scaleFactor?.toDouble() ?? 1.0;
    final screenWidth = (display.visibleSize?.width ?? 1920.0) / dpr;
    final size = Size(screenWidth, _kStripHeightLogical);

    await windowManager.waitUntilReadyToShow(
      WindowOptions(
        size: size,
        minimumSize: size,
        maximumSize: size,
        backgroundColor: const Color(0x00000000),
        skipTaskbar: true,
        titleBarStyle: TitleBarStyle.hidden,
        alwaysOnTop: true,
        windowButtonVisibility: false,
      ),
      () async {
        await windowManager.setResizable(false);
        await windowManager.setMinimumSize(size);
        await windowManager.setMaximumSize(size);
        await windowManager.show();
        // GTK may resize on show — force again after.
        await windowManager.setSize(size);
        await windowManager.setPosition(Offset.zero);
        await windowManager.setAlwaysOnTop(true);
      },
    );
  }
}
