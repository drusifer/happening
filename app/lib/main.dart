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
import 'package:happening/core/linux/click_through_capability.dart';
import 'package:happening/core/linux/click_through_channel.dart';
import 'package:happening/core/linux/linux_click_through_channel.dart';
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

  // 3. Detect Linux click-through capability via native channel.
  final capability = await _detectClickThroughCapability();
  final linuxTransparentSupported = capability.supported;
  _log.fine(
      'Linux click-through: backend=${capability.displayServer} supported=$linuxTransparentSupported');

  // 4. Initialize window management.
  final windowService = WindowService(
    windowManager: windowManager,
    screenRetriever: screenRetriever,
    supportsTransparentPassThroughForTesting:
        linuxTransparentSupported ? true : null,
  );
  final effectiveWindowMode = settingsSvc.current.effectiveWindowMode(
    defaultTargetPlatform,
    linuxTransparentSupported: linuxTransparentSupported,
  );
  await windowService.initialize(
    initialFontSize: settingsSvc.current.fontSize,
    initialWindowMode: effectiveWindowMode,
  );
  _log.fine('WindowService initialized.');

  // 5. Launch app with pre-loaded settings and window service.
  runApp(HappeningApp(
    settingsService: settingsSvc,
    windowService: windowService,
    linuxTransparentSupported: linuxTransparentSupported,
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

Future<ClickThroughCapability> _detectClickThroughCapability() async {
  if (!Platform.isLinux) return ClickThroughCapability.unsupported;
  final ClickThroughChannel channel = LinuxClickThroughChannel();
  return ClickThroughCapability.detect(channel);
}
