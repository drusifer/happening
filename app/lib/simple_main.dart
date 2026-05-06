import 'dart:async';
import 'package:flutter/material.dart';
import 'package:happening/core/settings/settings_service.dart';
import 'package:happening/core/window/window_service.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

// A simple main function to test the window resizing logic in isolation.
// To run this, you can temporarily modify `app/lib/main.dart` to call this main,
// or create a separate run configuration.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We need to initialize the window manager for the simple app.
  final windowService = WindowService(
    windowManager: WindowManager.instance,
    screenRetriever: ScreenRetriever.instance,
  );
  await windowService.initialize(initialFontSize: FontSize.medium);
  runApp(SimpleTestApp(windowService: windowService));
}

class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({super.key, required this.windowService});
  final WindowService windowService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SimpleResizeWidget(windowService: windowService),
      ),
    );
  }
}

class SimpleResizeWidget extends StatefulWidget {
  const SimpleResizeWidget({super.key, required this.windowService});
  final WindowService windowService;

  @override
  State<SimpleResizeWidget> createState() => _SimpleResizeWidgetState();
}

class _SimpleResizeWidgetState extends State<SimpleResizeWidget> {
  @override
  void initState() {
    super.initState();
    widget.windowService.isExpandedNotifier.addListener(_onExpansionChanged);
  }

  @override
  void dispose() {
    widget.windowService.isExpandedNotifier.removeListener(_onExpansionChanged);
    super.dispose();
  }

  void _onExpansionChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleEnter(PointerEvent details) {
    unawaited(widget.windowService.expand());
  }

  void _handleExit(PointerEvent details) {
    unawaited(widget.windowService.collapse());
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = widget.windowService.isExpandedNotifier.value;
    final height = isExpanded ? 320.0 : 50.0;
    final color = isExpanded ? Colors.blue : Colors.red;
    final text = isExpanded ? 'Expanded' : 'Collapsed';

    return MouseRegion(
      onEnter: _handleEnter,
      onExit: _handleExit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        color: color,
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
    );
  }
}
