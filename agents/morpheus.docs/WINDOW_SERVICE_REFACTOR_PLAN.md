# Window Service Refactor Plan — 2026-03-18

## Goal
Extract platform-specific resize logic into separate `WindowResizeStrategy` implementations.
`WindowService` becomes platform-agnostic — no `Platform.isXxx` checks anywhere.

## Interface

```dart
// lib/core/window/resize_strategy/window_resize_strategy.dart

abstract class WindowResizeStrategy {
  /// Factory — picks the right strategy for the current platform.
  static WindowResizeStrategy create({
    required WindowManager wm,
    required ScreenRetriever sr,
  }) {
    if (Platform.isWindows) return WindowsResizeStrategy(wm: wm, sr: sr);
    if (Platform.isLinux)   return LinuxResizeStrategy(wm: wm, sr: sr);
    return MacOsResizeStrategy(wm: wm, sr: sr);
  }

  /// Platform-specific window setup (AppBar registration, resizable flags, etc.)
  Future<void> initialize(Size initialSize, double dpr);

  /// Resize to expandedSize. Call [onExpanded] at the moment Flutter should
  /// rebuild with isExpanded=true (before resize on Windows, after on Linux).
  Future<void> expand(Size targetSize, VoidCallback onExpanded);

  /// Resize to collapsedSize. Flutter isExpanded=false is set by WindowService
  /// before this is called.
  Future<void> collapse(Size targetSize);

  /// Release any native resources (e.g. Win32 AppBar registration).
  void dispose() {}
}
```

## Strategy Implementations

### `LinuxResizeStrategy`
```
lib/core/window/resize_strategy/linux_resize_strategy.dart
```
- `initialize`: `setPosition(zero)`, `setAsFrameless()`, `show()`, `focus()` — NO `setResizable(false)`
- `expand`: `setSize(targetSize)`, then call `onExpanded()`
- `collapse`: `setSize(targetSize)`
- `dispose`: no-op

### `WindowsResizeStrategy`
```
lib/core/window/resize_strategy/windows_resize_strategy.dart
```
- Owns ALL Win32 FFI code: `_AppBarData` struct, `SHAppBarMessage`, `_registerAppBar()`, `_reserveCollapsedSpace()`
- `initialize`: `_registerAppBar()`, `setAsFrameless()`, `setResizable(false)`, `show()`, `focus()`
- `expand`: call `onExpanded()` first, then `setMaximumSize → setSize → setMinimumSize`
- `collapse`: `setMinimumSize → setMaximumSize → setSize`
- `dispose`: `SHAppBarMessage(ABM_REMOVE)`, `calloc.free()`

### `MacOsResizeStrategy`
```
lib/core/window/resize_strategy/macos_resize_strategy.dart
```
- `initialize`: `setPosition(zero)`, `setAsFrameless()`, `setResizable(false)`, `show()`, `focus()`
- `expand`/`collapse`: `setMaximumSize → setSize → setMinimumSize` (same as Windows, no AppBar)
- `dispose`: no-op

## WindowService After Refactor

```dart
class WindowService {
  WindowService({required WindowManager wm, required ScreenRetriever sr})
    : _wm = wm, _sr = sr,
      _strategy = WindowResizeStrategy.create(wm: wm, sr: sr);

  final WindowManager _wm;
  final ScreenRetriever _sr;
  final WindowResizeStrategy _strategy;

  // Shared state — stays here, not in strategy
  final isExpandedNotifier = ValueNotifier<bool>(false);
  bool _resizing = false;
  bool? _pendingWantsExpanded;
  FontSize _fontSize = FontSize.medium;
  double _dpr = 1.0;

  Future<void> initialize({FontSize initialFontSize = FontSize.medium}) async {
    await _wm.ensureInitialized();
    _fontSize = initialFontSize;
    _dpr = _wm.getDevicePixelRatio();
    final display = await _sr.getPrimaryDisplay();
    final size = Size(display.size.width, getCollapsedHeight());
    // No Platform checks here!
    final windowOptions = WindowOptions(...);
    await _wm.waitUntilReadyToShow(windowOptions, () async {
      await _strategy.initialize(size, _dpr);
    });
  }

  Future<void> _doExpand() async {
    _resizing = true;
    try {
      final display = await _sr.getPrimaryDisplay();
      final size = Size(display.size.width, getExpandedHeight());
      await _strategy.expand(size, () => isExpandedNotifier.value = true);
    } finally { _resizing = false; }
  }

  Future<void> _doCollapse() async {
    _resizing = true;
    try {
      isExpandedNotifier.value = false;
      final display = await _sr.getPrimaryDisplay();
      final size = Size(display.size.width, getCollapsedHeight());
      await _strategy.collapse(size);
    } finally { _resizing = false; }
  }

  void dispose() => _strategy.dispose();
  // expand(), collapse(), _checkPending(), getCollapsedHeight(), getExpandedHeight() — unchanged
}
```

## File Structure

```
lib/core/window/
  window_service.dart                          ← no Platform.isXxx, delegates to strategy
  resize_strategy/
    window_resize_strategy.dart               ← abstract class + factory
    linux_resize_strategy.dart                ← setSize only
    windows_resize_strategy.dart              ← win32 FFI + AppBar + 3-step sequence
    macos_resize_strategy.dart                ← frameless + setSize sequence
```

## Constraints
- `WindowService` public API unchanged (constructor, `expand()`, `collapse()`, `isExpandedNotifier`, `getCollapsedHeight()`, `getExpandedHeight()`)
- Window service tests updated to test via the public API (no change to test surface)
- Win32 code compiles on all platforms (win32 package is cross-platform safe)
- `updateHeights()` delegates to `_doExpand`/`_doCollapse` — unchanged

## Key Benefits
- Each platform strategy independently testable with a mock `WindowManager`
- Adding a new platform (e.g., Web, Wayland-native) = add one new class
- `WindowService` has zero platform knowledge
- Win32 FFI isolated to `windows_resize_strategy.dart`

## Assign To
@Neo *swe impl WINDOW_SERVICE_REFACTOR_PLAN.md (after PAINTER_REFACTOR_PLAN.md)
