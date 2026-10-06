# Task Board — Countdown Swing Sprint (F-33)
**Updated**: 2026-10-02 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith
**Tier**: 2 (fast-track) | Previous board: `docs/sprints/F-32/F32_TASK_BOARD_FINAL.md`

---

## Sprint Goal
In the final 10s before a meeting starts, the big shaking countdown swings fast
edge-to-edge across the full strip; stops at T=0; mouse-over snaps it back to its
regular position; OS reduce-motion disables it.

## Source Artifacts
- Stories & Architecture: `docs/sprints/F-33/F33_COUNTDOWN_SWING_STORIES_ARCH.md`
- Smith Gate Review: `docs/sprints/F-33/F33_SMITH_GATE_2026-10-02.md`

---

## Phase Board

| Phase | Status | Tasks | Owner |
|-------|--------|-------|-------|
| A — Pure swing logic | ⏳ TODO | F33-A1 | Neo + Trin |
| B — Strip integration | ⏳ TODO | F33-B1, F33-B2 | Neo + Trin |
| C — UAT | ⏳ TODO | F33-C1 | Trin + Smith |

---

## Phase A — Pure swing logic
**Gate**: unit tests green, analyzer clean.

### F33-A1: `CountdownSwing` (TDD)  ⏳ TODO
- **Goal**: new `app/lib/features/timeline/countdown_swing.dart` with
  `threshold` (10s), `sweep` (700ms), `isActive(...)` (AC-1, AC-7, AC-9 inputs)
  and `alignmentX(t) = -cos(πt)`.
- **Tests**: `app/test/features/timeline/countdown_swing_test.dart` — truth table
  per condition; boundaries 11s off / 10s on / 0s off; alignmentX at 0, 0.5, 1.

---

## Phase B — Strip integration
**Gate**: widget tests green, full suite no new failures, analyzer clean.

### F33-B1: Animation driver + pointer tracking  ⏳ TODO
- **Goal**: `TickerProviderStateMixin`; `_swingAnim` (700ms, `repeat(reverse: true)`);
  `_updateSwing(active)`; `_isPointerInWindow` set at the top of `_handleMouse`
  (before early returns), cleared on exit; same-frame stop on enter (AC-7);
  dispose controller.
  **Rule**: never start/stop `_swingAnim` synchronously inside a build/builder —
  pick the layout branch from `CountdownSwing.isActive`, defer controller calls
  via `addPostFrameCallback` (see arch §2.2).
- **Files**: `app/lib/features/timeline/timeline_strip.dart`

### F33-B2: Swing layout  ⏳ TODO
- **Goal**: in `_buildCountdownPositioned`, when active use full-width
  `Positioned` → `RepaintBoundary` → `AnimatedBuilder` → `Align(Alignment(x,0))`
  and pass the same alignment to `_CountdownContentSpec.alignment` (AC-2).
  Inactive path unchanged. Mini/hidden path untouched.
- **Tests** (`timeline_strip_test.dart`, `enableAnimations: true`): swing at 8s
  reaches both edges; none at 15s; none for meeting-end countdown; pointer enter
  snaps back / exit resumes; stops at 0; none with `disableAnimations: true`;
  tap-to-mute still works while swinging (AC-6).

---

## Phase C — UAT
### F33-C1: Manual UAT on macOS  ⏳ TODO
- Trin: run app with a meeting ~30s out; verify AC-1..AC-9.
- Smith: `*user test` — legibility of 3× glyph over event labels; hover feel.
