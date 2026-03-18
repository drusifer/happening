# Current Task

## ARCH-002: Fix LinuxResizeStrategy.expand() — 2026-03-18
**Status**: PENDING ⏳ — ready to implement on resume

### The Bug
`LinuxResizeStrategy.expand()` uses wrong order. Window stays at 60px after expand.
All logs show `isExpanded=true` but `maxHeight=60.0` = window never actually resizes.

### Root Cause
New order: `setMaximumSize(260) → setSize(260) → setMinimumSize(260)` — WRONG
- Lifts max first → valid constraints throughout → GTK has no conflict to resolve → no force

Required order (pre-S6): `setSize(260) → setMinimumSize(260) → setMaximumSize(260)` — CORRECT
- setSize(260) advisory, ignored (max still 60)
- setMinimumSize(260): NOW min=260 > max=60 = INVALID → GTK forces grow to 260
- setMaximumSize(260): formalise

### Fix Location
`app/lib/core/window/resize_strategy/linux_resize_strategy.dart`

```dart
@override
Future<void> expand(Size targetSize, void Function() onExpanded) async {
  await _wm.setSize(targetSize);
  await _wm.setMinimumSize(targetSize);  // min > old_max forces GTK to grow
  await _wm.setMaximumSize(targetSize);
  onExpanded();
}
```

### Tests to Update
- `test/core/window/window_resize_strategy_test.dart` — LinuxResizeStrategy expand order test
- `test/core/window/window_linux_e2e_test.dart` — expand E2E test (update _GtkStyleWindowManager to model min>max growth)

### Done This Session
- [x] Sprint 6: T-01→T-10 ALL COMPLETE (217→223 tests) ✅
- [x] ARCH-001: LinuxResizeStrategy.collapse() restored to 3-step ✅
- [x] HoverController wired into TimelineStrip ✅
- [x] LinuxHoverController suppress timer fixed ✅
- [ ] ARCH-002: expand() order — NEXT
