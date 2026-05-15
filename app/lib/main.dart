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
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';
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

  // 3. Initialize window management.
  final windowService = WindowService(
    windowManager: windowManager,
    screenRetriever: screenRetriever,
  );
  await windowService.initialize(
    initialFontSize: settingsSvc.current.fontSize,
    initialWindowMode: settingsSvc.current.effectiveWindowMode,
  );
  _log.fine('WindowService initialized.');

  // 4. Launch app with pre-loaded settings and window service.
  runApp(HappeningApp(
    settingsService: settingsSvc,
    windowService: windowService,
  ));
  _log.fine('runApp() executed.');
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
    final line = '[${r.time.toIso8601String()}] [$tag] [${r.loggerName}] ${r.message}';
    debugPrint(line);
    if (r.level >= Level.INFO) {
      logFile?.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    }
  });
}

