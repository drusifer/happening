# Architectural Analysis: Window Resize Race Conditions
**Date**: 2026-03-18 | **Author**: Morpheus | **Triggered by**: Trin BUG-A + BUG-B

---

## Root Cause: Non-Atomic Async IPC Chains

Window resize on desktop = a chain of async IPC calls to the OS compositor:
```
setSize() → setMinimumSize() → setMaximumSize()
```
Each `await` yields the event loop. If two resize chains start concurrently, their steps interleave:

```
[expand]  setSize(260) ─────────────────────────────── setMax(200) ← BUG: collapse's max
[collapse]            setSize(200) ─── setMax(200) ──────────────────────────────────
                      WRONG: expand's setMax receives collapse's constraint → stuck at 200px
```

This is the exact pattern seen in `log-sample.txt` lines 89-95.

---

## Bug Inventory

### BUG-A: Concurrent Expand/Collapse Race
**Symptom**: Window stuck at 200px (neither 60px collapsed nor 260px expanded).
**Root cause**: Two coroutines (`_doExpand`, `_doCollapse`) running concurrently — no mutual exclusion.
**Fix**: `AsyncGate<bool>` — serialises all resize requests, keeps only the last pending intent.
**Status**: ✅ FIXED in Sprint 6. Regression tests added.

### BUG-B: Sprint 6 Regression — Linux resize broken
**Symptom**: After `collapse()`, window stays at expanded height (260px). Reported by Drew in manual testing.
**Root cause**: Sprint 6 `LinuxResizeStrategy.collapse()` calls `setSize()` only. On GTK/Wayland, `setSize()` is advisory — compositor ignores it when the window has a non-zero minimum size set from a prior expand.
**Confirmed via git diff**: Pre-Sprint6 `_doCollapse()` had explicit documentation:
```
/// GTK/Wayland resize order for collapse:
///   setMinimumSize first → allow shrink below previous min.
///   setMaximumSize       → lock max so compositor can't re-expand.
///   setSize last         → resize (constraints already permit it).
```
Sprint 6 deleted this documented knowledge when creating `LinuxResizeStrategy`.
**E2E repro tests**: 3 failing tests in `test/core/window/window_linux_e2e_test.dart` confirm it.
**Status**: ✅ FIXED — ARCH-001 restored 3-step (setSize→setMin→setMax). 2026-03-18.

---

## Architectural Patterns Evaluated

### Pattern 1: Mutex (AsyncGate) — IMPLEMENTED ✅
```dart
class AsyncGate<T> {
  // Drops intermediate requests, executes only first + last
}
```
**Pros**: Simple, correct for hover expand/collapse (last intent wins).
**Cons**: Callers can't await final completion (pending fires `unawaited`).
**Verdict**: Correct for this use case. Keep.

### Pattern 2: Constraint-Forcing for Linux
**Problem**: `setSize()` on GTK is advisory. `setMaximumSize()` is mandatory.
**Fix**: Align `LinuxResizeStrategy` with Windows/macOS pattern:

```
Current Linux collapse:
  setSize(target)                    ← advisory, may be ignored

Recommended Linux collapse:
  setMinimumSize(Size.zero)          ← allow shrink
  setMaximumSize(target)             ← FORCE max to target height
  setSize(target)                    ← advisory (belt-and-suspenders)
```

This mirrors what the OLD pre-Sprint6 code did (which DID work on Linux).

### Pattern 3: State Machine for Window
**Would add**: Explicit states COLLAPSED / EXPANDING / EXPANDED / COLLAPSING with transition guards.
**Verdict**: Overkill for a 2-state system. AsyncGate achieves the same safety with less code.

### Pattern 4: Verify-and-Retry Strategy
**Would add**: After `setSize()`, call `getSize()` and compare. If mismatched, fall back to constraint forcing.
**Verdict**: Useful as a debug diagnostic but too complex for production. Prefer constraint-first always.

---

## How Sprint 6 Changes Hold Up

| Concern | Sprint 6 Change | Verdict |
|---|---|---|
| Race condition (BUG-A) | Added `AsyncGate<bool>` | ✅ FIXED. Serialises expand/collapse. Regression tests pass. |
| Linux collapse (BUG-B) | Created `LinuxResizeStrategy` | ✅ FIXED (ARCH-001). 3-step restored: setSize→setMin→setMax. 2026-03-18. |
| Linux expand (BUG-C) | `LinuxResizeStrategy.expand()` wrong order | ✅ FIXED (ARCH-002). Corrected to setSize→setMin→setMax. min>max forces GTK grow. 2026-03-18. |
| AsyncGate dedup | No dedup, redundant re-runs possible | ✅ FIXED (ARCH-003). Same-as-inflight cancels pending reversal. 2026-03-18. |
| Platform isolation | `WindowResizeStrategy` abstraction | ✅ CORRECT design. All platforms now correctly implemented. |

**The E2E test (`window_linux_e2e_test.dart`) is correctly calibrated.** Drew's concern about it relying too much on fakes is valid in principle, but the `_GtkStyleWindowManager` fake is grounded in pre-Sprint6 source comments AND log evidence. It's not an arbitrary mock — it encodes documented GTK behavior. The 3 FAILING tests are the correct repro.

---

## Recommended Action

### Immediate (BUG-B risk mitigation)
Update `LinuxResizeStrategy` to use constraint-forcing pattern for collapse:
```dart
@override
Future<void> collapse(Size targetSize) async {
  await _wm.setMinimumSize(Size.zero);       // allow shrink
  await _wm.setMaximumSize(targetSize);      // force constraint
  await _wm.setSize(targetSize);             // advisory
}
```

### Test Coverage
- BUG-A: ✅ 2 regression tests added (`window_service_test.dart`)
- BUG-B: ✅ 1 characterisation test added (documents gap, passes if state is consistent)
- BUG-B Linux fix: needs a new strategy test verifying setMinimumSize+setMaximumSize called on collapse

---

## Decisions

> **ARCH-001** ✅ DONE: `LinuxResizeStrategy.collapse()` uses setSize→setMin→setMax. setMaximumSize forces shrink.

> **ARCH-002** ✅ DONE: `LinuxResizeStrategy.expand()` uses setSize→setMin→setMax. setMinimumSize with min>max forces GTK grow. DO NOT lift max first — it removes the conflict that triggers growth.

> **ARCH-003** ✅ DONE: `AsyncGate` upgraded — same-as-inflight cancels pending reversal. Same-as-pending deduped. Prevents redundant resize ops after GTK spurious event bursts.

**Manual UAT passed 2026-03-18 (Drew).**
