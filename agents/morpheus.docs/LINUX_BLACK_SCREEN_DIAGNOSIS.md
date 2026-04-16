# Linux Black Screen Diagnosis — 2026-04-15

## Symptom
Intermittent: timestrip all black and/or expanded section all black after Windows overlap fixes.

## What Changed (since last good Linux state at 4e8471c)
New code added in `a54185d`: `WidgetsBindingObserver`/`didChangeMetrics` on `WindowService`.
Previously (4e8471c), WindowService had NO `WidgetsBindingObserver`. This is new.

## Root Cause Hypothesis

`_onDisplayChanged()` is called by `didChangeMetrics`, which Flutter fires on Linux
**every time the window is resized** (not just display changes).

The guard `if (newDpr == _dpr && newWidth == _screenWidth) return;` should prevent
spurious triggers — but:

1. `_wm.getDevicePixelRatio()` is called first (sync)
2. `await _sr.getPrimaryDisplay()` suspends the function

During that await, LinuxResizeStrategy may have already mutated the window. On some
Linux setups (fractional scaling, Wayland), the DPR or reported screen width can
transiently differ during an active resize.

If the guard passes, `_doCollapse()` or `_doExpand()` is called **directly, bypassing
`_gate`**. This races with the ongoing `LinuxResizeStrategy` ops.

Interleaved `setSize/setMinimumSize/setMaximumSize` at conflicting heights can leave:
- Window at wrong size
- `isExpandedNotifier` in wrong state
- Flutter layout out of sync with OS window size

→ Flutter renders expanded layout in a 55px window (or vice versa) → black.

Intermittent because the race depends on async timing.

## Secondary Hypothesis
`didChangeMetrics` fires multiple times per expand/collapse (once per setSize,
setMinimumSize, setMaximumSize call). Each concurrent `_onDisplayChanged()` hits
`await _sr.getPrimaryDisplay()` in parallel. Under timing pressure, one might
see a stale/transitional DPR and pass the guard.

## Logging Plan (to confirm)
1. `_onDisplayChanged()`: log EVERY invocation with old/new DPR and width (even early returns)
2. `_doExpand()` / `_doCollapse()`: log caller site (gate vs onDisplayChanged)
3. `LinuxResizeStrategy.expand()` / `collapse()`: log each step with target
4. `TimelineStrip.build()`: log `constraints.maxHeight`, `isExpanded`, `_collapsedHeight`
5. `TimelinePainter.paint()`: log `size`

## Fix (after logging confirms)
Option A (safest): On non-Windows, `_onDisplayChanged()` should ONLY update `_dpr`/`_screenWidth`
and NOT call `_doExpand()`/`_doCollapse()` directly. On Linux the resize strategy
owns the window size — no need to re-trigger resize from a display-metrics callback.

Option B: Route `_doExpand()`/`_doCollapse()` calls from `_onDisplayChanged()` through `_gate`.
