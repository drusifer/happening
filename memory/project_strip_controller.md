---
name: StripController window convergence
description: All window transitions converged onto WindowService.applyState, gated by StripController; ExpansionController/performResize deleted (DEC-009, 2026-06)
type: project
---

As of 2026-06-21 (DEC-009), every window transition routes through ONE applier —
`WindowService.applyState(StripState)` — gated by `StripController`. This SUPERSEDES the
older ExpansionController refactor (that subsystem is gone).

**Why:** Divergent per-transition paths (`ExpansionController`, `resizeToMini/FullStrip`,
`_doExpand/_doCollapse`, `performResize`) each re-implemented reservation/positioning slightly
differently — the root cause of the recurring "strip lands below its own strut" bug.

**What changed:**
- DELETED: `ExpansionController`, `ResizeExecutor`, `WindowServiceResizeExecutor`,
  `PhysicalWindowState`, `performResize`, `_doExpand/_doCollapse`.
- `StripController` (a `ChangeNotifier`; owns `StripState {collapsedShown, expandedShown, hidden}`;
  serialized by `AsyncGate`, one-slot last-wins) is the single gate: `collapse/expand/hide/show/reapply`.
- `applyState` reserves the work-area band FIRST (`applyReservation`), then sizes at the reserved
  origin. Reserve-before-position keeps the strip in its strut.
- Dispatch: `→hidden` = `hideStrip`; `hidden→shown` = `showStrip` (+ first-frame present);
  `shown→shown` = `applyState`.

**How to apply:** Drive transitions via `StripController` (`expand/collapse/hide/show`).
`WindowService.applyState` is the only OS-geometry primitive. Validated on Windows; Linux/macOS
show/hide still use the base `resizeToFull/Mini` + `onShow/HideStrip` path (deferred to those
systems). See `docs/ARCH.md` §6 and `docs/DECISIONS.md` DEC-009.
