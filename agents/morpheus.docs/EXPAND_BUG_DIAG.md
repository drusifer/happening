# Expand Bug Diagnosis — 2026-05-09

## Verdict

Neo followed the plan correctly. All 3 phases implemented as designed. The bug is an **architectural gap the plan did not cover**.

## Root Cause — Re-trigger Loop

`_handleMouse` calls `_expansionController.send(state)` on **every mouse move**, not just on state transitions. The EC's "last-write-wins queue" was designed for sparse callers. With hover sending continuously:

1. Mouse over strip → `send(expanded)` fires on every micro-move
2. EC executes expand; `Duration.zero` timeout fires on next tick → confirms done
3. Pending `expanded` from queue → EC executes ANOTHER expand immediately
4. `LinuxResizeStrategy.expand()` 4-step GTK sequence runs in a tight loop
5. GTK receives rapid repeated resize commands → state diverges → non-deterministic

**Confirmed from build-expand-black3.out:**
```
[EC] timeout fallback: actual=340.0 target=340.0
[EC] execute DONE intent=expanded target=340.0
[EC] execute START intent=expanded target=340.0   ← immediately!
LinuxResizeStrategy.expand() START ...
```
This pattern repeats on every hover event while expanded.

## Black Screen

During the rapid re-expand loop, GTK's internal constraint state (min/max) is being written repeatedly in the 4-step sequence. Under rapid churn:
- GTK may process resize ops out of the expected order
- The ARGB compositing surface can be disrupted by rapid constraint changes
- Flutter's layout surface can desynch from the physical GTK window size

## Fix — Minimal and Surgical

**File:** `app/lib/features/timeline/timeline_strip.dart`

**Step 1** — Add a field to `_TimelineStripState`:
```dart
ExpansionState? _lastMouseSentState;
```

**Step 2** — In `_handleMouse()`, replace:
```dart
_expansionController.send(state);
```
with:
```dart
if (state != _lastMouseSentState) {
  _lastMouseSentState = state;
  _expansionController.send(state);
}
```

**Step 3** — Reset in `_resetToFreshCollapsedState()`, before the direct send:
```dart
_lastMouseSentState = null;
```

**Why not reset to `collapsed`?** Setting null forces re-evaluation on next hover so the dedup doesn't block a legitimate expand if state was unclear before reset.

## Callers That Must NOT Be Deduped

These callers bypass `_handleMouse` and call `send()` directly — they need force-execute semantics for sleep/resume and settings reliability. Do NOT add dedup to them:

- `_clearInteractiveState()` — focus loss → must force collapse
- `_toggleSettings()` — expand/collapse for settings panel
- `didChangeAppLifecycleState()` — sleep/resume → must force collapse
- `_resetToFreshCollapsedState()` — explicit reset

## Test Plan

1. `make test` — ensure 292/292 green (no regressions)
2. `make run-linux` — manual UAT:
   - Hover strip → expands once, stays expanded, no repeated GTK calls in log
   - Move mouse within expanded strip → NO `[EC] execute START` in log while hovering
   - Exit strip → collapses once
   - Hover again → expands again (dedup cleared on collapse)
   - Repeat 10+ times — should be deterministic every time
   - No black screen on any expand
