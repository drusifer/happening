# Current Task

## Linux Window Resize Fix — 2026-03-18
**Status**: IN PROGRESS 🔴

### Done
- [x] Identified BUG-A (race condition) — fixed by AsyncGate ✅
- [x] Identified BUG-B (Linux setSize no-op) — confirmed Sprint 6 regression ✅
- [x] Issued ARCH-001: restore collapse 3-step to LinuxResizeStrategy ✅
- [x] HoverController wired into TimelineStrip ✅
- [x] LinuxHoverController suppress timer fixed (only on actual expand) ✅
- [x] Diagnosed BUG-C: expand order wrong — ARCH-002 issued ✅

### Next (ARCH-002)
- [ ] @Neo *swe fix ARCH-002: revert LinuxResizeStrategy.expand() to pre-S6 order
  - MUST BE: `setSize(target) → setMinimumSize(target) → setMaximumSize(target)`
  - DO NOT lift max first — the min>max conflict is the actual forcing mechanism on GTK
  - Also check: should `onExpanded()` fire after all resize ops complete?
- [ ] @Trin *qa verify manual test — hover card visible + no black screen

### Key Files
- `app/lib/core/window/resize_strategy/linux_resize_strategy.dart` ← NEEDS FIX
- `app/test/core/window/window_resize_strategy_test.dart` ← update expand order test
- `app/test/core/window/window_linux_e2e_test.dart` ← expand E2E test needs update
