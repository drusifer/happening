---
name: ExpansionController refactor
description: All 3 phases complete — AsyncGate/isExpandedNotifier/hover controllers removed; performResize() is the new entry point
type: project
---

All 3 phases DONE as of 2026-05-06. 292/292 green.

**Why:** Timing races (expand-black, invisible card, startup GTK constraint reset) caused by scattered expand/collapse state across 6+ call sites.

**What changed:**
- Phase 1: `PhysicalWindowState`, `ResizeExecutor`, `ExpansionController` (queue + GTK confirmation via didChangeMetrics)
- Phase 2: `WindowServiceResizeExecutor`, `TimelineStrip` wired to `ExpansionController`; stream drives card visibility
- Phase 3: `WindowService` cleanup — removed `AsyncGate`, `_wantsExpanded`, `isExpandedNotifier`, `expand()`/`collapse()`, `resetToFreshCollapsedState()`, `didChangeAppLifecycleState` collapse logic, `LinuxHoverController`, `DefaultHoverController`, `HoverController`. Added `performResize(ExpansionState intent)`.

**How to apply:** `WindowService.performResize()` is the only public resize entry point. `ExpansionController.send()` is the UX-layer entry point. Never add back `expand()`/`collapse()` or `isExpandedNotifier`.
