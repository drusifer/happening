# Card Visibility Fix Plan — 2026-03-18

## Problem
Window expands (isExpanded=true) but hover cards not visible after a few mouse-overs.

## Root Cause
`expand()` and `collapse()` are both `async`, called with `unawaited()` on every mouse-move
(onHover fires 10-20x/sec). Their 3-step resize sequences interleave:

```
_doExpand()  after setMinimumSize: Size(2944, 260) ✓
_doCollapse() after setSize: Size(2944, 200)       ← INTERLEAVED mid-expand
_doExpand()  after setMaximumSize: Size(2944, 200) ← DONE at wrong size!
```

Window is "expanded" but locked at 200px. Card zone is 57→260px — bottom half clipped.
The `Future.delayed(100ms)` in `_doCollapse` (line 307, Linux path) amplifies the race.

## Fix — window_service.dart only (platform-neutral)

### Change 1: Remove `Future.delayed(100ms)` from `_doCollapse` Linux path (line 307)
Was a workaround for GTK, now makes races worse.

### Change 2: Add `_resizing` guard + `_pendingWantsExpanded`
```dart
bool _resizing = false;
bool? _pendingWantsExpanded;

Future<void> expand() async {
  if (_resizing) { _pendingWantsExpanded = true; return; }
  await _doExpand();
  _checkPending();
}

Future<void> collapse() async {
  if (_resizing) { _pendingWantsExpanded = false; return; }
  await _doCollapse();
  _checkPending();
}

void _checkPending() {
  final p = _pendingWantsExpanded; _pendingWantsExpanded = null;
  if (p == true) unawaited(expand());
  if (p == false) unawaited(collapse());
}
```

In `_doExpand` and `_doCollapse`:
- Set `_resizing = true` at entry
- Reset `_resizing = false` in `finally` block

## Why This Works
- Concurrent calls queue the *last* intent (not all intermediate ones)
- After resize completes, pending intent fires once → correct final state guaranteed
- No debounce needed in TimelineStrip
- No Platform.isXxx checks — same logic on all platforms

## Files Changed
- `app/lib/core/window/window_service.dart` only

## Assign To
@Neo *swe impl CARD_VISIBILITY_FIX_PLAN.md
