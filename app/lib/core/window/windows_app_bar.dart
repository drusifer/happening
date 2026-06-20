import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';
import 'package:logging/logging.dart';
import 'package:win32/win32.dart';

/// Native Win32 seam for the timeline strip's window operations.
///
/// TLDR:
/// Overview: Abstracts the Win32 AppBar (work-area reservation) + RedrawWindow
///           present calls behind an interface so `WindowsWindowService` can be
///           unit-tested with a fake. The real impl ([Win32AppBar]) holds the
///           APPBARDATA handle and talks to shell32/user32 via FFI.
/// Problem: The AppBar/FFI was inline in WindowsWindowService, so the entire
///          Windows init + reservation orchestration was untestable — the
///          1px-sliver / position-below-strut regressions had ZERO unit
///          coverage and could only be caught by a manual desktop run.
/// Solution: A thin [WindowsAppBar] seam: register / reserveTopBand / dispose /
///           presentFrame. Tests inject a fake to assert ordering, dispose on
///           hide, and reserve dimensions; only true OS compositing stays manual.
/// Breaking Changes: No (extraction; behaviour unchanged).
abstract class WindowsAppBar {
  /// Whether an AppBar handle is currently registered with Windows.
  bool get isRegistered;

  /// Finds the Flutter HWND, allocates APPBARDATA, and registers it (ABM_NEW).
  /// No-op if already registered.
  void register();

  /// Reserves a top work-area band of [widthPx] × [heightPx] (physical px) via
  /// ABM_QUERYPOS → ABM_SETPOS. Returns the rcTop (physical px) Windows
  /// assigned for the band — expected to be 0 for a top edge.
  int reserveTopBand({required int widthPx, required int heightPx});

  /// Full re-broadcast cycle (ABM_REMOVE → ABM_NEW → reserve) so Windows
  /// re-announces the work area to all apps. Returns the assigned rcTop.
  int reassertTopBand({required int widthPx, required int heightPx});

  /// Removes the reservation (ABM_REMOVE) and frees the handle. No-op if not
  /// registered.
  void dispose();

  /// Forces a single OS-level present of the window (RedrawWindow with
  /// RDW_INVALIDATE | RDW_UPDATENOW). No geometry change.
  void presentFrame();
}

// ── Win32 constants ──────────────────────────────────────────────────────────

const int _uCallbackMessage = 0x0400 + 100; // WM_USER + 100
const int _abmNew = 0;
const int _abmRemove = 1;
const int _abmQuerypos = 2;
const int _abmSetpos = 3;
const int _abeTop = 1;

/// Flutter Windows runner class name — used to find the HWND.
const String _flutterWindowClass = 'FLUTTER_RUNNER_WIN32_WINDOW';

// ── APPBARDATA FFI struct ────────────────────────────────────────────────────

final class _AppBarData extends Struct {
  @Uint32()
  external int cbSize;
  @IntPtr()
  external int hWnd;
  @Uint32()
  external int uCallbackMessage;
  @Uint32()
  external int uEdge;
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

typedef _SHNative = IntPtr Function(
    Uint32 dwMessage, Pointer<_AppBarData> pData);
typedef _SHDart = int Function(int dwMessage, Pointer<_AppBarData> pData);

/// Real FFI-backed [WindowsAppBar]. Only constructed on Windows.
class Win32AppBar implements WindowsAppBar {
  static final _log = Logger('Win32AppBar');

  Pointer<_AppBarData>? _data;
  _SHDart? _shFn;

  /// Lazily resolves SHAppBarMessage once and caches it across register/dispose
  /// cycles (a `late final` here threw on the second register after a hide).
  _SHDart get _sh => _shFn ??= () {
        _log.fine('loading SHAppBarMessage from shell32.dll');
        return DynamicLibrary.open('shell32.dll')
            .lookupFunction<_SHNative, _SHDart>('SHAppBarMessage');
      }();

  int _findHwndAddress() {
    final classNamePtr = _flutterWindowClass.toNativeUtf16();
    final hwnd = FindWindow(PCWSTR(classNamePtr), null);
    calloc.free(classNamePtr);
    return hwnd.value.address;
  }

  @override
  bool get isRegistered => _data != null;

  @override
  void register() {
    if (_data != null) return;
    final hwndAddr = _findHwndAddress();
    _data = calloc<_AppBarData>();
    _data!.ref.cbSize = sizeOf<_AppBarData>();
    _data!.ref.hWnd = hwndAddr;
    _data!.ref.uCallbackMessage = _uCallbackMessage;
    _sh(_abmNew, _data!);
    _log.fine('register: ABM_NEW hWnd=0x${hwndAddr.toRadixString(16)}');
  }

  @override
  int reserveTopBand({required int widthPx, required int heightPx}) {
    final d = _data!;
    d.ref.uEdge = _abeTop;
    d.ref.rcLeft = 0;
    d.ref.rcTop = 0;
    d.ref.rcRight = widthPx;
    d.ref.rcBottom = heightPx;
    _sh(_abmQuerypos, d);
    _sh(_abmSetpos, d);
    _log.fine(
        'reserveTopBand: req=${widthPx}x$heightPx → rect=[${d.ref.rcLeft},${d.ref.rcTop},${d.ref.rcRight},${d.ref.rcBottom}]');
    return d.ref.rcTop;
  }

  @override
  int reassertTopBand({required int widthPx, required int heightPx}) {
    _sh(_abmRemove, _data!);
    _sh(_abmNew, _data!);
    _log.fine('reassertTopBand: ABM_REMOVE → ABM_NEW done, reserving');
    return reserveTopBand(widthPx: widthPx, heightPx: heightPx);
  }

  @override
  void dispose() {
    if (_data != null) {
      _sh(_abmRemove, _data!);
      calloc.free(_data!);
      _data = null;
      _log.fine('dispose: ABM_REMOVE done');
    }
  }

  @override
  void presentFrame() {
    final classNamePtr = _flutterWindowClass.toNativeUtf16();
    final hwnd = FindWindow(PCWSTR(classNamePtr), null);
    calloc.free(classNamePtr);
    if (hwnd.value.address == 0) {
      _log.warning('presentFrame: HWND not found, skipping');
      return;
    }
    _log.fine(
        'presentFrame: RedrawWindow(RDW_INVALIDATE|RDW_UPDATENOW) hwnd=0x${hwnd.value.address.toRadixString(16)}');
    RedrawWindow(hwnd.value, nullptr, null,
        REDRAW_WINDOW_FLAGS(RDW_INVALIDATE | RDW_UPDATENOW));
  }
}
