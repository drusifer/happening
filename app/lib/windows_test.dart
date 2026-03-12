// Windows AppBar expand/collapse test harness.
//
// Tests SHAppBarMessage-based space reservation + window resize on Windows.
// win32 v5 dropped SHAppBarMessage bindings — defined here via raw FFI.
//
// Run with: make run-windows-test

import 'dart:async';
import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:win32/win32.dart'; // FindWindow, Utf16 helpers
import 'package:window_manager/window_manager.dart';

// ── Constants ────────────────────────────────────────────────────────────────

const double _collapsedHeight = 50.0;
const double _expandedHeight = 250.0;
const int _uCallbackMessage = 0x0400 + 100; // WM_USER + 100

const int _abmNew = 0;
const int _abmRemove = 1;
const int _abmQuerypos = 2;
const int _abmSetpos = 3;
const int _abeTop = 1;

// Flutter Windows runner class name — used to find the HWND.
const String _flutterWindowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

// ── APPBARDATA FFI struct ────────────────────────────────────────────────────
// Manual definition — not included in win32 v5 bindings.
// Layout (64-bit): cbSize(4)+pad(4)+hWnd(8)+uCallback(4)+uEdge(4)+RECT(16)+lParam(8) = 48 bytes

final class _AppBarData extends Struct {
  @Uint32()
  external int cbSize;

  // 4 bytes implicit padding added by Dart FFI to align hWnd to 8 bytes.

  @IntPtr()
  external int hWnd;

  @Uint32()
  external int uCallbackMessage;

  @Uint32()
  external int uEdge;

  // Inlined RECT fields (left, top, right, bottom).
  @Int32()
  external int rcLeft;
  @Int32()
  external int rcTop;
  @Int32()
  external int rcRight;
  @Int32()
  external int rcBottom;

  @IntPtr()
  external int lParam;
}

// ── SHAppBarMessage via shell32.dll ──────────────────────────────────────────

typedef _SHNative = IntPtr Function(Uint32 dwMessage, Pointer<_AppBarData> pData);
typedef _SHDart = int Function(int dwMessage, Pointer<_AppBarData> pData);

final _shAppBarMessage = DynamicLibrary.open('shell32.dll')
    .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');

// ── Entry point ──────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final display = await ScreenRetriever.instance.getPrimaryDisplay();
  final width = display.size.width;

  final windowOptions = WindowOptions(
    size: Size(width, _collapsedHeight),
    alwaysOnTop: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,
    titleBarStyle: TitleBarStyle.hidden,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.setPosition(Offset.zero);
    await windowManager.setResizable(false);
    await windowManager.show();
    await windowManager.focus();
  });

  // Find the Flutter window HWND by class name (more reliable than GetActiveWindow).
  final classNamePtr = _flutterWindowClass.toNativeUtf16();
  final res = FindWindow(PCWSTR(classNamePtr), PCWSTR(nullptr));
  final hwnd = res.value;
  calloc.free(classNamePtr);

  // Register as a Windows AppBar so the shell reserves screen space.
  final appBarData = calloc<_AppBarData>();
  appBarData.ref.cbSize = sizeOf<_AppBarData>();
  appBarData.ref.hWnd = hwnd.address;
  appBarData.ref.uCallbackMessage = _uCallbackMessage;
  _shAppBarMessage(_abmNew, appBarData);

  runApp(WindowsTestApp(appBarDataPtr: appBarData.address));
}

// ── App ──────────────────────────────────────────────────────────────────────

class WindowsTestApp extends StatelessWidget {
  const WindowsTestApp({super.key, required this.appBarDataPtr});
  final int appBarDataPtr;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _WindowsResizeWidget(
          appBarData: Pointer.fromAddress(appBarDataPtr),
        ),
      ),
    );
  }
}

// ── Widget ───────────────────────────────────────────────────────────────────

class _WindowsResizeWidget extends StatefulWidget {
  const _WindowsResizeWidget({required this.appBarData});
  final Pointer<_AppBarData> appBarData;

  @override
  State<_WindowsResizeWidget> createState() => __WindowsResizeWidgetState();
}

class __WindowsResizeWidgetState extends State<_WindowsResizeWidget> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_reserveCollapsedSpace());
  }

  @override
  void dispose() {
    _shAppBarMessage(_abmRemove, widget.appBarData);
    calloc.free(widget.appBarData);
    super.dispose();
  }

  // Reserves the collapsed strip height with Windows Shell — called once at init.
  // Proper sequence: QUERYPOS lets Windows adjust rc to avoid other AppBars,
  // SETPOS confirms it, then we move the window to the approved coordinates.
  // Expansion overlaps other windows like a dropdown; the reservation never changes.
  Future<void> _reserveCollapsedSpace() async {
    final display = await ScreenRetriever.instance.getPrimaryDisplay();
    widget.appBarData.ref.uEdge = _abeTop;
    widget.appBarData.ref.rcLeft = 0;
    widget.appBarData.ref.rcTop = 0;
    widget.appBarData.ref.rcRight = display.size.width.toInt();
    widget.appBarData.ref.rcBottom = _collapsedHeight.toInt();
    // Step 1: ask Windows to adjust rc to avoid conflicts with other AppBars.
    _shAppBarMessage(_abmQuerypos, widget.appBarData);
    // Step 2: confirm the (possibly adjusted) position.
    _shAppBarMessage(_abmSetpos, widget.appBarData);
    // Step 3: ABM_SETPOS does NOT move the window — we must do it ourselves.
    await windowManager.setPosition(Offset(
      widget.appBarData.ref.rcLeft.toDouble(),
      widget.appBarData.ref.rcTop.toDouble(),
    ));
  }

  Future<void> _expand() async {
    if (_isExpanded) return;
    setState(() => _isExpanded = true);
    final display = await ScreenRetriever.instance.getPrimaryDisplay();
    await windowManager.setSize(Size(display.size.width, _expandedHeight));
  }

  Future<void> _collapse() async {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
    final display = await ScreenRetriever.instance.getPrimaryDisplay();
    await windowManager.setSize(Size(display.size.width, _collapsedHeight));
  }

  @override
  Widget build(BuildContext context) {
    final color = _isExpanded ? Colors.blue : Colors.red;
    final text = _isExpanded ? 'Expanded' : 'Collapsed';

    return MouseRegion(
      onEnter: (_) => unawaited(_expand()),
      onExit: (_) => unawaited(_collapse()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: _isExpanded ? _expandedHeight : _collapsedHeight,
        color: color,
        child: Center(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ),
    );
  }
}
