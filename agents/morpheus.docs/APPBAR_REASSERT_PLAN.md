# AppBar Re-assertion Plan

## Goal
Make the timeline strip's AppBar reservation self-healing:
- Refresh button gives users a reliable escape hatch to recover overlapped windows
- Periodic timer re-asserts the reservation as a background safety net

---

## Changes

### 1. `window_service.dart` — two additions

#### A. `reassertAppBar()` — public, Windows-only

Full re-registration: `ABM_REMOVE` → `ABM_NEW` → `_reserveCollapsedSpace()`.
Forces Windows to re-broadcast updated work area to all running apps.

```dart
/// Re-registers the AppBar with Windows, restoring work area reservation.
/// Call when the strip is observed to be overlapping other windows.
/// No-op on non-Windows platforms.
Future<void> reassertAppBar() async {
  if (!Platform.isWindows || _appBarData == null) return;
  _shAppBarMessage(_abmRemove, _appBarData!);
  _shAppBarMessage(_abmNew, _appBarData!);
  await _reserveCollapsedSpace();
}
```

#### B. Periodic timer — Windows-only, 60s interval

Re-calls `_reserveCollapsedSpace()` (softer than full re-registration — just `ABM_SETPOS`).
Catches cases where callbacks are missed (DPI change, display change).

New field:
```dart
Timer? _appBarTimer;
```

Start in `initialize()` after `_registerAppBar()`:
```dart
if (Platform.isWindows) {
  _appBarTimer = Timer.periodic(
    const Duration(seconds: 60),
    (_) => unawaited(_reserveCollapsedSpace()),
  );
}
```

Cancel in `dispose()`:
```dart
_appBarTimer?.cancel();
```

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
| `app/lib/core/window/window_service.dart` | Add `reassertAppBar()`, `_appBarTimer`, start/cancel timer |
| `app/lib/features/timeline/timeline_strip.dart` | Refresh `onTap` calls both `refresh()` + `reassertAppBar()` |

---

## Rules (add to LESSONS.md after confirmed)

- AppBar reservation can go stale after DPI change or display change. Re-call `ABM_SETPOS` to restore.
- Full re-registration (`ABM_REMOVE` + `ABM_NEW`) is the reliable recovery path — re-broadcasts work area to all running apps.
- `ABM_REMOVE` + `ABM_NEW` is safe to call at runtime as long as the HWND is valid.

---

## Out of scope

- Handling `WM_DISPLAYCHANGE` / `WM_DPICHANGED` / `ABN_POSCHANGED` via Win32 subclassing (future sprint — requires native plugin or message hook beyond current FFI scope)
- Apps that actively ignore work area (Zoom etc.) — no workaround possible without a global keyboard hook
