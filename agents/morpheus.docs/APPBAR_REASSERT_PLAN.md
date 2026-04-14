# AppBar Re-assertion Plan

**Status**: Shipped 2026-04-14.

Final implementation differs from the first plan: the periodic timer was removed after it caused the window to shrink to ~136px when it fired. The shipped self-healing path is `didChangeMetrics()` plus a manual refresh-button reassert.

## Goal
Make the timeline strip's AppBar reservation self-healing:
- Refresh button gives users a reliable escape hatch to recover overlapped windows
- Flutter display-metric changes refresh screen width/DPI and re-assert the reservation

---

## Changes

### 1. `window_service.dart` — shipped additions

#### A. `reassertAppBar()` — public, Windows-only

Full re-registration: `ABM_REMOVE` -> `ABM_NEW` -> `_reserveCollapsedSpace()`.
Forces Windows to re-broadcast updated work area to all running apps.

```dart
/// Re-registers the AppBar with Windows, restoring work area reservation.
/// Call when the strip is observed to be overlapping other windows.
/// No-op on non-Windows platforms.
Future<void> reassertAppBar() async {
  if (!Platform.isWindows || _appBarData == null) return;
  await _doCollapse();
  _shAppBarMessage(_abmRemove, _appBarData!);
  _shAppBarMessage(_abmNew, _appBarData!);
  await _reserveCollapsedSpace();
  await _wm.setPosition(Offset(0, _appBarData!.ref.rcTop / _dpr));
  await _doCollapse();
}
```

#### B. `didChangeMetrics()` — refresh screen size and DPI

`WindowService` observes Flutter display metric changes. On each event it refreshes:
- DPR via `window_manager.getDevicePixelRatio()`
- primary display width via `screen_retriever.getPrimaryDisplay().size.width`

If either changed, it updates cached `_dpr`/`_screenWidth`, reasserts the Windows AppBar band with updated physical-pixel values, repositions using trusted `rcTop / dpr`, then re-runs the current resize state.

```dart
@override
void didChangeMetrics() {
  unawaited(_onDisplayChanged());
}

Future<void> _onDisplayChanged() async {
  final newDpr = _wm.getDevicePixelRatio();
  final display = await _sr.getPrimaryDisplay();
  final newWidth = display.size.width;

  if (newDpr == _dpr && newWidth == _screenWidth) return;

  _dpr = newDpr;
  _screenWidth = newWidth;

  if (Platform.isWindows && _appBarData != null) {
    await _reserveCollapsedSpace();
    await _wm.setPosition(Offset(0, _appBarData!.ref.rcTop / _dpr));
  }

  if (isExpandedNotifier.value) {
    await _doExpand();
  } else {
    await _doCollapse();
  }
}
```

#### C. Periodic timer — removed

The planned 60s Windows-only `_reserveCollapsedSpace()` timer was tested and removed because it caused the window to shrink to ~136px when it fired. Metrics-driven refresh plus manual refresh-button reassert is the current recovery strategy.

---

### 2. `timeline_strip.dart` — refresh button

Change the refresh button `onTap` from a single call to a combined call:

**Before:**
```dart
onTap: widget.calendarController!.refresh,
```

**After:**
```dart
onTap: () {
  unawaited(widget.calendarController!.refresh());
  unawaited(_windowService.reassertAppBar());
},
```

---

## Files Changed

| File | Change |
|------|--------|
| `app/lib/core/window/window_service.dart` | Add `reassertAppBar()`, `didChangeMetrics()`, `_onDisplayChanged()` |
| `app/lib/features/timeline/timeline_strip.dart` | Refresh `onTap` calls both `refresh()` + `reassertAppBar()` |

---

## Rules (add to LESSONS.md after confirmed)

- AppBar reservation can go stale after DPI change or display change. Re-call `ABM_SETPOS` to restore.
- Full re-registration (`ABM_REMOVE` + `ABM_NEW`) is the reliable recovery path — re-broadcasts work area to all running apps.
- `ABM_REMOVE` + `ABM_NEW` is safe to call at runtime as long as the HWND is valid.
- DPR and primary display width must be refreshed on `didChangeMetrics()`; do not rely on launch-time values.
- Periodic AppBar reassert is not currently safe; the timer shrink regression makes it a rejected approach.

---

## Out of scope

- Handling `ABN_POSCHANGED` via Win32 subclassing (future sprint — requires native plugin or message hook beyond current FFI scope)
- Apps that actively ignore work area (Zoom etc.) — no workaround possible without a global keyboard hook
