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
import 'package:happening/core/window/window_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load settings once to get initial window height
  final home = Platform.environment['HOME'] ?? '';
  final dir = Directory('$home/.config/happening');
  final settingsSvc = SettingsService(directory: dir);
  await settingsSvc.load();

  // Scale vertical strip height padding: Small -> +16, Medium -> +20, Large -> +24
  final padding = switch (settingsSvc.current.fontSize) {
    FontSize.small => 16.0,
    FontSize.medium => 20.0,
    FontSize.large => 24.0,
  };
  final initialHeight = settingsSvc.current.fontSize.px + padding;

  await WindowService().initialize(height: initialHeight);
  runApp(const HappeningApp());
}
