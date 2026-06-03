// App entry point.
//
// TLDR:
// Overview: Bootstraps the Flutter application.
// Problem: Need a clean entry point to initialize services and launch the UI.
// Solution: Initializes WindowService and runs HappeningApp.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:happening/app.dart';
import 'package:happening/core/display/display_service.dart';
import 'package:happening/core/display/screen_retriever_adapter.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/linux_window_service.dart';
import 'package:happening/core/window/macos_window_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:happening/core/window/windows_window_service.dart';
import 'package:logging/logging.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

final _log = Logger('main');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Logger.
  final home = Platform.environment['HOME'] ?? '';
  final dir = Directory('$home/.config/happening');
  _setupLogging(dir);
  _log.fine('Main entry point: WidgetsFlutterBinding initialized.');

  // 2. Load settings once at the root to determine initial UI state/size.
  final settingsSvc = SettingsService(directory: dir);
  await settingsSvc.load();
  _log.fine('Settings loaded.');

  // 3. Initialize DisplayService (resolves which display the strip lives on).
  final displayService = DisplayService(
    probe: ScreenRetrieverDisplayProbe(screenRetriever),
    events: ScreenRetrieverDisplayEvents(screenRetriever),
    initialChoice: settingsSvc.current.chosenDisplay,
    onWeakMatch: (choice, display) {
      _log.warning(
          'DisplayService: weak fingerprint match — persisted=${choice.osName} '
          'matched ${display.id} (${display.osName}). User can re-pick in Settings.');
    },
  );
  await displayService.initialize();
  _log.fine(
      'DisplayService initialized: active=${displayService.activeDisplay}');

  // 4. Initialize window management.
  final WindowService windowService;
  if (Platform.isMacOS) {
    windowService = MacOSWindowService(
      windowManager: windowManager,
      screenRetriever: screenRetriever,
      displayService: displayService,
    );
  } else if (Platform.isWindows) {
    windowService = WindowsWindowService(
      windowManager: windowManager,
      screenRetriever: screenRetriever,
      displayService: displayService,
    );
  } else {
    windowService = LinuxWindowService(
      windowManager: windowManager,
      screenRetriever: screenRetriever,
      displayService: displayService,
    );
  }
  _log.info('WindowService.initialize() start');
  await windowService.initialize(
    initialFontSizePx: settingsSvc.current.fontSizePx,
    initialWindowMode: settingsSvc.current.effectiveWindowMode,
  );
  _log.info('WindowService.initialize() done — calling runApp()');

  // 5. Launch app with pre-loaded settings and window service.
  runApp(HappeningApp(
    settingsService: settingsSvc,
    windowService: windowService,
    displayService: displayService,
  ));
  _log.info('runApp() returned');
}

void _setupLogging(Directory dir) {
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;

  File? logFile;
  if (!dir.existsSync()) dir.createSync(recursive: true);
  logFile = File('${dir.path}/debug.log');
  Logger.root.info('--- APP STARTUP ---');

  Logger.root.onRecord.listen((r) {
    final tag = r.level >= Level.SEVERE
        ? 'ERR'
        : r.level >= Level.WARNING
            ? 'WRN'
            : r.level >= Level.INFO
                ? 'INF'
                : 'DBG';
    final line =
        '[${r.time.toIso8601String()}] [$tag] [${r.loggerName}] ${r.message}';
    debugPrint(line);
    if (r.level >= Level.INFO) {
      logFile?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    }
  });
}
