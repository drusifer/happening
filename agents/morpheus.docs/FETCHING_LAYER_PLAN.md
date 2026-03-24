# Refactor Plan: Loading State via FetchingLayer

**Author:** Morpheus
**Date:** 2026-03-23
**Status:** Awaiting approval

---

## Problem

`app.dart` swaps `_LoadingStrip` ↔ `TimelineStrip` when `events == null`. This tears down
and recreates `TimelineStrip`'s expensive state (HoverController, WidgetsBindingObserver,
timers, WindowService) mid-flight — the source of loading-state race conditions.

---

## Goal

`TimelineStrip` mounts once and stays mounted for the entire authenticated session.
Loading state is rendered entirely inside the existing painter compositor stack.

---

## Changes

### File 1 — `app/lib/features/timeline/painters/fetching_layer.dart` *(new)*

New `TimelineLayer` implementation. Fits the existing compositor pattern — implements
`paint(Canvas canvas, Size size)` and no-ops when not loading.

**Behaviour when `isLoading == true`:**
- Fill entire canvas with `backgroundColor` (same color as `BackgroundLayer`) to
  cover the empty-but-painted timeline layers beneath it
- Draw centered italic "Fetching calendars..." text at 50% opacity using `textColor`
  and `fontSize`

**Behaviour when `isLoading == false`:** return immediately, paint nothing.

**Constructor params:**
```dart
const FetchingLayer({
  required this.isLoading,
  required this.backgroundColor,
  required this.textColor,
  required this.fontSize,
});
```

---

### File 2 — `app/lib/features/timeline/timeline_painter.dart`

- Add `isLoading` param (`bool`, default `false`)
- Add `textColor` param (`Color`) — passed through to `FetchingLayer`
- Append `FetchingLayer` as the **last** entry in the `layers` list so it paints
  over all other layers when active:

```dart
final layers = [
  BackgroundLayer(color: backgroundColor),
  PastOverlayLayer(...),
  TickLayer(...),
  EventsLayer(...),
  NowIndicatorLayer(...),
  FetchingLayer(                          // ← new, last
    isLoading: isLoading,
    backgroundColor: backgroundColor,
    textColor: textColor,
    fontSize: fontSize,
  ),
];
```

- Add `old.isLoading != isLoading` to `shouldRepaint`

---

### File 3 — `app/lib/features/timeline/timeline_strip.dart`

- Add `isLoading` param to `TimelineStrip` widget (`bool`, default `false`)
- Thread it through to `TimelinePainter` at the `CustomPaint` call site (~line 406):

```dart
TimelinePainter(
  ...
  isLoading: widget.isLoading,          // ← new
  textColor: theme.textTheme.bodyMedium?.color ?? Colors.white,
)
```

---

### File 4 — `app/lib/app.dart`

- Remove `_LoadingStrip` class entirely (~lines 226–251)
- Change the `authenticated` StreamBuilder branch — always render `TimelineStrip`,
  never null-guard to a different widget:

```dart
_AuthState.authenticated => StreamBuilder<List<CalendarEvent>>(
  stream: _calendar!.events,
  initialData: _calendar!.lastEvents,
  builder: (context, eventSnapshot) {
    return TimelineStrip(
      events: eventSnapshot.data ?? const [],
      isLoading: eventSnapshot.data == null,
      clockService: _clock,
      calendarController: _calendar!,
      settingsService: widget.settingsService,
      windowService: widget.windowService,
      onSignOut: _signOut,
    );
  },
),
```

---

## What Stays the Same

- Compositor loop in `TimelinePainter` — unchanged
- All existing layers (`BackgroundLayer`, `TickLayer`, etc.) — unchanged
- `_SignInStrip` — unchanged (different auth state)
- All existing tests — `isLoading` defaults to `false`, no behaviour change

---

## Test Coverage (new)

- **`FetchingLayer` unit test:** assert paints when `isLoading=true`, no-ops when `false`
- **`TimelinePainter` shouldRepaint:** assert repaints on `isLoading` change
- **`app.dart` widget test:** assert `_LoadingStrip` is gone; assert `TimelineStrip`
  is present immediately on auth with `events == null`
