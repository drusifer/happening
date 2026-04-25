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

import 'package:flutter/material.dart';
import 'package:happening/app.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/util/logger.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Logger.
  final home = Platform.environment['HOME'] ?? '';
  final dir = Directory('$home/.config/happening');
  await AppLogger.initialize(dir);
  await AppLogger.debug('Main entry point: WidgetsFlutterBinding initialized.');

  // 2. Load settings once at the root to determine initial UI state/size.
  final settingsSvc = SettingsService(directory: dir);
  await settingsSvc.load();
  await AppLogger.debug('Settings loaded.');

  // 3. Initialize window management.
  final windowService = WindowService(
    windowManager: windowManager,
    screenRetriever: screenRetriever,
  );
  final effectiveWindowMode =
      settingsSvc.current.effectiveWindowMode(defaultTargetPlatform);
  await windowService.initialize(
    initialFontSize: settingsSvc.current.fontSize,
    initialWindowMode: effectiveWindowMode,
  );
  await AppLogger.debug('WindowService initialized.');

  // 5. Launch app with pre-loaded settings and window service.
  runApp(HappeningApp(
    settingsService: settingsSvc,
    windowService: windowService,
  ));
  await AppLogger.debug('runApp() executed.');
}
