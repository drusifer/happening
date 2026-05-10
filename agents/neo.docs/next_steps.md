# Next Steps — ExpansionController Complete

## All 3 phases done. 292/292 green.

## What was done
- Phase 1: PhysicalWindowState, ResizeExecutor, ExpansionController + tests
- Phase 2: WindowServiceResizeExecutor, TimelineStrip wired, stream drives card visibility
- Phase 3: WindowService cleanup — removed AsyncGate/isExpandedNotifier/expand/collapse/hover controllers

## Manual UAT recommended
- Wayland smoke test: hover expand/collapse works, no black card
- Sleep/resume: window re-collapses correctly via ExpansionController no-skip guarantee
- Display change (monitor connect/disconnect): window resizes to new width

## If bugs found
- Check `ExpansionController.didChangeMetrics()` — fires when GTK confirms
- Check `WindowServiceResizeExecutor.resize()` calls `performResize()`
- Check `_isExpanded` in `WindowService._onDisplayChangedInner()` is accurate
