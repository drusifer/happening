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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Logger.
  final home = Platform.environment['HOME'] ?? '';
  final dir = Directory('$home/.config/happening');
  await AppLogger.initialize(dir);
  await AppLogger.log('Main entry point: WidgetsFlutterBinding initialized.');

  // 2. Load settings once at the root to determine initial UI state/size.
  final settingsSvc = SettingsService(directory: dir);
  await settingsSvc.load();
  await AppLogger.log('Settings loaded.');

  // 3. Determine initial window height from settings.
  final padding = switch (settingsSvc.current.fontSize) {
    FontSize.small => 16.0,
    FontSize.medium => 20.0,
    FontSize.large => 24.0,
  };
  final initialHeight = settingsSvc.current.fontSize.px + padding;
  final expandedHeight = 160.0;
  await AppLogger.log('Calculated initial window height: $initialHeight expanded: $expandedHeight');

  // 4. Initialize window management.
  final windowService = WindowService();
  await windowService.initialize(height: initialHeight, expandedHeight: expandedHeight);
  await AppLogger.log('WindowService initialized.');

  // 5. Launch app with pre-loaded settings and window service.
  runApp(HappeningApp(
    settingsService: settingsSvc,
    windowService: windowService,
  ));
  await AppLogger.log('runApp() executed.');
}
