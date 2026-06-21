# Window Entrypoint Convergence — Plan

**Author:** Neo (*swe)  **Status:** Draft for review
**Date:** 2026-06-19
**Related:** `docs/WINDOW_STATE_REFACTOR_PLAN.md`, `docs/WINDOW_STATE_REFACTOR_REVIEW_2026-06-17.md`,
LESSONS L-006 (model OS behavior in fakes), L-005 (applySize bracket)

---

## 1. Problem

We built a single, unified applier — `WindowService.applyState(StripState)` (reserve-then-position,
idempotent) — and then wired **only one caller** to it (init). Every other window transition is still
a bespoke path with its own reservation + positioning logic:

| Entrypoint | Path today | Uses `applyState`? |
|---|---|---|
| init | `afterWindowShown → applyState(collapsedShown)` | ✅ |
| refresh | `reassertAppBar → _appBar.dispose() + applyState(collapsedShown)` | ⚠️ + gratuitous `ABM_REMOVE` |
| hide | `_hideStrip → prepareToHide(onHideStrip: dispose) + resizeToMiniStrip(applySize)` | ❌ |
| show | `_showStrip → resizeToFullStrip(applySize) + completeShow(onShowStrip: register+reserve+setPosition)` | ❌ |
| expand / collapse | `ExpansionController → performResize → _doExpand/_doCollapse` (in-place applySize; no reservation, no reposition) | ❌ |
| display change | `_onDisplayChangedInner → _doExpand/_doCollapse + onDisplayChangedExtra` | ❌ |
| font change | `updateHeights → _doExpand/_doCollapse` | ❌ |

**Consequence:** init works; the others intermittently strand the strip below the strut. They are
literally different code doing similar-but-not-identical things, so we have been fixing the same
class of bug once per path ("works here / breaks there"). This is the drifting-paths bug class the
whole refactor set out to delete.

## 2. Evidence (why this is the right lever)

Delayed position probes (`GEO[... +Nms]`, real run `build.below.out` 2026-06-19 22:55) proved the
stranding is an **asynchronous OS relocation**, not a bug in our positioning logic:

| Path | sync `GEO` | +150ms | +500ms | +1200ms |
|------|-----------|--------|--------|---------|
| init applyState / present | (0,0) | (0,0) | (0,0) | (0,0) ✅ |
| refresh #1 | (0,0) | **(0,73)** | (0,73) | (0,73) ❌ |
| refresh #2 | (0,0) | (0,0) | (0,0) | (0,0) ✅ |
| show (resizeFull / onShow) | (0,0) | **(0,73)** | (0,73) | (0,73) ❌ |
| refresh #3 (post-show) | (0,0) | (0,0) | (0,0) | (0,0) ✅ |

We set the window to `(0,0)`; it reads back `(0,0)` synchronously; then **Windows moves it to
`(0,73)` within ~150ms** — outside our `AsyncGate`, so serializing our own calls cannot catch it.

**Trigger correlation:** the drift fires only on an `ABM_REMOVE → ABM_NEW` re-registration cycle
while the window is at `(0,0)` (inside the band). It does **not** fire on a fresh `ABM_NEW` (init),
nor when the window was already at `(0,73)` before re-reserving (refresh #2/#3). This matches the
"it's `ABM_REMOVE`" hypothesis: the **gratuitous teardown** on refresh/reassert is what perturbs the
window; init never tears down, so it never drifts.

## 2a. Resolved decisions (Drew, 2026-06-19)

- **Refresh = refresh calendars only.** The strut `reassertAppBar` on the refresh button was a
  band-aid added *because* of the non-deterministic strut behavior — i.e. a workaround for the bug
  this plan fixes. Once the strut is deterministic, the refresh button reverts to just
  `calendarController.refresh()` (+ idempotent view reset). It does **not** reclaim/re-broadcast the
  strut, so it needs no teardown and cannot drift. `reassertAppBar` is removed from the button.
- **Buttons should give visual click feedback** (pressed/ripple) — a base button behavior currently
  missing on the toolbar icons. Small UX item, folded into this work.
- **`onWindowMoved` re-pin: approved** to handle the one legitimate hide→show teardown (re-adds the
  `WindowListener` removed with `onWindowFocus`).
- **Window-resize animation: deferred.** Expand/collapse currently *snaps* (never animated).
  Convergence makes the snap uniform and gives one place (`applyState`) to animate later; building
  the animated resize is a follow-up, not part of this convergence.

## 2b. Revised decision (Drew, 2026-06-20) — convergence FIRST, re-pin contingent

Manual gate (`build-still-below-strut.out`): init keeps the strip in its strut; **show stranded it
below**. Side-by-side trace pinned the divergence — the show path (`resizeToFullStrip` → `onShowStrip`)
sizes the window BEFORE reserving and never presents, whereas init (`applyState` reserve→size +
`presentInitialFrame`) reserves first, sizes at the reserved origin, then presents.

- **Make show *be* init.** Don't invent a new mechanism. Route show through the exact sequence init
  uses. Implemented as `WindowService.showStrip()`: base keeps the legacy two-step (Linux/macOS
  strut lives in `onShowStrip`, untouched); **Windows overrides** it to `applyState(collapsedShown)`
  + `presentInitialFrame()`. `_showStrip` (widget) now makes one call.
- **§4.3 `onWindowMoved` re-pin: DROPPED — VALIDATED 2026-06-20.** It was approved on 2026-06-19 as
  *the* synchronization fix, but it is a new mechanism. Pure convergence was tried first and **the
  manual gate confirmed it (build-no-strut-issues.md): every hide→show now holds pos=(0,0) through the
  +150/+500/+1200ms probes — no drift.** This empirically DISPROVES the "REMOVE→NEW always relocates"
  hypothesis: the real cause was the inverted order (size-before-reserve) + the missing present, both
  of which init avoids. The re-pin is not needed and stays out unless a future path reintroduces drift.
- **Test scope honesty (L-006).** The unit harness models a window grown PAST its band (rule a). It
  cannot decide whether the OS async-relocates a same-size re-registration — that is the manual gate.
  So the converged show is covered by call-sequence tests (reserve-before-size + present, like init);
  the strut-position outcome is verified on the real machine.

## 3. Goal & Principles

1. **One applier.** Every transition routes through `applyState(targetState)`, serialized by the
   one gate (`StripController` / `AsyncGate`). No bespoke geometry/reservation paths remain.
2. **`applyState` owns everything:** size (`_sizeFor`), position (reserved origin), and reservation.
3. **`ABM_REMOVE` only on `→ hidden`.** A shown→shown re-apply (refresh, reassert, expand, collapse,
   display/font change) re-`ABM_SETPOS`es the **existing** AppBar — no teardown. This removes every
   *gratuitous* `REMOVE→NEW` and kills the refresh/reassert drift at the root.
4. **One legitimate teardown remains:** hide releases the strut (`ABM_REMOVE`), show re-acquires it
   (`ABM_NEW`). This single unavoidable `REMOVE→NEW` is handled by an `onWindowMoved` re-pin — in one
   place — that reconciles an OS-initiated move back to the reserved origin.
5. **Idempotent, last-wins** (unchanged): racing transitions settle on the most recently requested
   state.

## 4. Target Architecture

### 4.1 Single gate
`StripController` (a `ChangeNotifier`, owns `StripState`, serialized by `AsyncGate`) is the only
caller of `WindowService.applyState`. Transition API: `collapse() / expand() / hide() / show() /
reapply()`. `ExpansionController` folds into it (it already owns the gate).

### 4.2 The applier (unchanged contract, now used everywhere)
```
applyState(state):
  size   = _sizeFor(state)
  origin = applyReservation(state)            // reserve FIRST, returns reserved origin
  applySize(size, position: origin)           // then place
```
`applyReservation(state)` (Windows):
- `shown + reserved`: register **iff not registered**; then `reserveTopBand` (re-`ABM_SETPOS`,
  **no `ABM_REMOVE`**). Return `Offset(workAreaOrigin.dx, rcTop/dpr)`.
- `hidden` or `overlay`: `dispose()` (the one place `ABM_REMOVE` is allowed). Return null.

### 4.3 OS-move reconciliation (the synchronization fix)
`WindowsWindowService` re-adds a `WindowListener`. On `onWindowMoved`, if the current state is
shown+reserved and the window has drifted off the reserved origin, snap it back with
`setPosition(reservedOrigin)`. Loop-safe: a correction that lands *on* the origin produces no further
correction. Models the hide→show `REMOVE→NEW` relocation that can't be avoided.

### 4.4 Entrypoint mapping (after)
```
init            → StripController.collapse()  → applyState(collapsedShown)
refresh         → calendarController.refresh() + view reset   (NO window/strut op at all)
hide            → StripController.hide()       → applyState(hidden)           (dispose: release strut)
show            → StripController.collapse()  → applyState(collapsedShown)   (register+reserve)
expand          → StripController.expand()    → applyState(expandedShown)
collapse        → StripController.collapse()  → applyState(collapsedShown)
display change  → StripController.reapply()    → applyState(currentState)
font change     → StripController.reapply()    → applyState(currentState)
```

## 5. What gets deleted

- `WindowService.resizeToMiniStrip` / `resizeToFullStrip` (subsumed by `applyState(hidden/collapsedShown)`).
- `onHideStrip` / `onShowStrip` reservation hooks (logic already in `applyReservation`).
- `_doExpand` / `_doCollapse` and `performResize` (replaced by `applyState`).
- `reassertAppBar`'s bespoke `dispose + performResize/setPosition` dance → plain `applyState(collapsedShown)`.
- `ExpansionController` as a separate object (folds into `StripController`).
- `WindowServiceResizeExecutor` if no longer needed.

## 6. Migration sequence (each step compiles + window tests green; probes stay in)

1. **Refresh → calendars only + button click feedback.** Drop `reassertAppBar` from the refresh
   button (it was the strut band-aid); button refreshes calendars + resets the view, no window op.
   Add pressed/ripple feedback to the toolbar `_IconButton`s. ← smallest change, removes one drift
   source immediately, and confirms refresh-without-teardown does not drift.
2. **Converge hide / show.** `_showStrip → windowService.showStrip()` (Windows = init's
   `applyState(collapsedShown)` + `presentInitialFrame`) — **DONE 2026-06-20** (see §2b). Hide next:
   `_hideStrip → applyState(hidden)`; then delete `resizeToMini/Full`, `onHide/ShowStrip`. Hide is
   the only `ABM_REMOVE` — where the teardown hypothesis gets validated. **MANUAL GATE show first.**
3. **CONTINGENT — `onWindowMoved` re-pin (§2b/§4.3).** Only if the manual gate STILL shows show
   drifting below the strut after step 2. If so, model the relocation → move event in
   `FakeWin32Desktop` and add a regression test (L-006 method). If convergence alone fixes it, this
   step is dropped.
4. **Converge expand / collapse + display / font change.** Route through the controller; fold
   `ExpansionController` in; delete `_doExpand/_doCollapse`, `performResize`, dead `resize*`.
   `onWindowModeChanged` routes through `applyState` too → `reassertAppBar` fully deletable.
5. **Cleanup.** Remove now-dead executor; reconcile remaining diagnostic logging (keep `GEO`
   per Drew's standing instruction — see `feedback_keep_debug_logging.md`).

## 7. Testing strategy

- Model the OS reaction in `FakeWin32Desktop` (L-006): (a) window taller than band → relocate
  (done); (b) `ABM_REMOVE→ABM_NEW` while at the band origin → async move event → relocate; assert
  the **resulting** `desktop.position`, and prove each test fails on the bug before trusting it.
- Unit-test the single applier once, thoroughly, instead of five divergent paths.
- DPI: keep the fractional-DPI test (band `ceil`, L-006 corollary).
- Compositing (sliver) remains real-run only — be explicit about what unit tests do/don't cover.
- Manual gate (Windows): init, refresh, hide→show, expand/collapse, multi-monitor — strip stays in
  the strut on every path; `GEO[... +Nms]` reads `(0,0)` for shown states.

## 8. Risks / Open questions

- **Animation vs geometry.** Expand height + hide fade are widget animations (`_hideAnim`, tween);
  converging geometry through `applyState` must keep those as view-only animators driven by state,
  not let the controller's discrete `applyState` snap away a smooth transition. Confirm expand still
  feels animated (the window resize was already immediate; the card fade is the animation).
- **`onWindowMoved` vs legitimate moves.** Display change / `moveToDisplay` legitimately repositions.
  The re-pin must compare against the *current* reserved origin (recomputed per state), not a stale
  one, and must not fight an in-progress transition (gate-aware).
- **macOS / Linux.** Convergence is Windows-validated; Linux strut + macOS deferred-show attach via
  the same seams. Keep them overridable; validate/ship separately (review B3).
- **`reapply()` dedup.** Display/font change keeps the same `StripState` but needs new geometry —
  must `force` through the gate (already supported), not be deduped as "same value".
