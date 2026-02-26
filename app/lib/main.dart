import 'package:flutter/material.dart';
import 'package:happening/app.dart';
import 'package:happening/core/window/window_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WindowService.initialize();
  runApp(const HappeningApp());
}
