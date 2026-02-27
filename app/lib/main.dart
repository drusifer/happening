/// App entry point.
///
/// TLDR:
/// Overview: Bootstraps the Flutter application.
/// Problem: Need a clean entry point to initialize services and launch the UI.
/// Solution: Initializes WindowService and runs HappeningApp.
/// Breaking Changes: No.
///
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/app.dart';
import 'package:happening/core/window/window_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowService.initialize();
  runApp(const HappeningApp());
}
