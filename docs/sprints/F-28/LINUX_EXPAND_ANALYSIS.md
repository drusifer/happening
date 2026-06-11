# Linux Expand Bug Analysis — 2026-03-23

## Symptoms
- "All black" or "no cards showing" on hover
- Both symptoms = same root cause

## Log Evidence
From `~/.config/happening/debug.log` (2026-03-23):
```
WindowService: _doExpand() target=260.0
Building _IconButton isExpanded=true _collapsedHeight=57.0 maxHeight=60.0
TimelinePainter.paint size=Size(2944.0, 57.0) sedHeight=57.0 maxHeight=60.0
```
`_doExpand()` fires, `isExpandedNotifier=true` is set, but **painter always sees maxHeight=60 and size=57**. GTK never resizes the window.

## Root Cause — Wrong Order in `LinuxResizeStrategy.expand()`

### Current code (BROKEN):
```dart
await _wm.setSize(targetSize);        // advisory — IGNORED (max=60 cap in place)
await _wm.setMinimumSize(targetSize); // min=260 > max=60 = INVALID CONFLICT
await _wm.setMaximumSize(targetSize); // clears conflict but growth unreliable
```
`setMinimumSize` with `max < min` creates an invalid constraint. GTK conflict resolution is **compositor-dependent and unpredictable** — works sometimes (explains the flakiness), not others.

### Old working code (2026-03-08 log confirmed):
```
_doExpand() after setMaximumSize: Size(2944.0, 200.0)   ← window at old size
_doExpand() after setMinimumSize: Size(2944.0, 240.0)   ← GTK GREW
```
Order was: `setMaximumSize(target)` → `setMinimumSize(target)` → WORKED reliably.

### Why the old order works:
1. `setMaximumSize(260)`: lifts cap. State: `min=60, max=260, window=60`. Valid, no change.
2. `setMinimumSize(260)`: raises floor. State: `min=260, max=260, window=60 < min`. **GTK MUST grow to satisfy min constraint** — this is well-defined, standard GTK behavior.

The forcing mechanism is NOT the min>max conflict — it's **GTK's guarantee that window_size >= min_size**.

## Fix

**`linux_resize_strategy.dart` only** — no Windows/macOS impact.

```dart
// expand(): setMaximumSize FIRST (lift cap), then setMinimumSize (raise floor → GTK grows)
await _wm.setMaximumSize(targetSize);
await _wm.setMinimumSize(targetSize);
onExpanded();

// collapse(): UNCHANGED — setSize → setMinimumSize → setMaximumSize still correct
```

Drop the `setSize` advisory call from expand — it's ignored when max-cap is in place and adds confusion.

## Why Both Symptoms Occur
When `isExpanded=true` but window stays at 60px:
- **All black**: Dark mode, `isExpanded=true` → Flutter renders 60px container with opaque `stripBackgroundColor` → entire visible area is dark strip = "all black"
- **No cards**: Hover card positioned at `top: 57` (collapsedHeight), window max=60 → only 3px visible → "no cards"
