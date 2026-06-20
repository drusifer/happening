# Window State-Machine Refactor — *lead review (Morpheus)

**Reviewer:** Morpheus (*lead)  **Date:** 2026-06-17
**Reviewing:** `docs/WINDOW_STATE_REFACTOR_PLAN.md` (Neo, draft)
**Verdict:** **APPROVED — direction is correct — CONDITIONAL on 5 blocking items below.**

---

## Verdict

The thesis is right. The bug class — *one end-state reached by N drifting, order-dependent
paths* — is real, and collapsing every geometry path onto `trigger → StripState → applyState →
applySize` is the correct structural fix. Geometry-as-a-pure-function-of-state (principle 2) +
one idempotent applier is the model I'd prescribe. The `presentInitialFrame` insight (the
sliver is OS compositing, not Flutter paint, proven by the `events=17` repaint that *didn't*
composite) is well-evidenced. Build on `applySize`/L-005 — don't touch that seam.

I am approving the architecture. The conditions below are not "maybe" — they're load-bearing
gaps where the plan would either re-introduce a race we already killed or carry forward the
complication we're trying to delete. Resolve them in the design before step 2.

---

## Direction (Drew, 2026-06-17) — binding framing

These reframe the review; where they conflict with the original conditions, they win.

1. **This is a state-transition API.** The deliverable is a small, idempotent transition surface
   (`collapse/expand/hide/show` + reactive re-apply) that the rest of the app calls. Other code
   gets *simpler* because it stops sequencing geometry and just declares the desired state.
2. **Idempotent, last-wins.** Concurrent/racing transitions always settle on the most recently
   requested state. This is the `AsyncGate` no-skip/last-wins contract (B1) elevated to *the*
   organising principle, not a defensive guard.
3. **Refactor the init complication away — don't preserve it.** Treat existing window-lifecycle
   comments as **suspect**: many things were tried over time. We are not carefully threading
   `onWindowFocus`/safety-net/`waitUntilReadyToShow`-callback semantics — we are **deleting** that
   layer and owning a deterministic show sequence. (See revised B2.)
4. **Windows-first; plan the rest, ship it separately.** Build and verify on Windows now. Keep
   the platform seam (`performShow` timing, `presentInitialFrame`, `_applyReservation`) overridable
   so macOS/Linux slot in later — but do **not** gate this work on their validation. The end state
   is *fewer* platform differences, with the transition API platform-agnostic above the seam.

---

## Blocking items (must resolve before/with implementation)

### B1 — `applyState` MUST run through the existing serialization gate *(highest risk)*
The plan presents `applyState` as a bare `async` method with no queueing. We already fought and
won the expand/collapse race (Sprint 6 BUG-A) by serialising through `ExpansionController` →
`AsyncGate` (no-skip, last-wins). A second, ungated geometry path resurrects that bug. Also note
`_onDisplayChanged` has its own `_displayChangeInProgress` guard today.
**Decision:** every `applyState` call funnels through the existing resize executor / `AsyncGate`
seam. Do not add a parallel unserialised path. Step 1 must wire this, not defer it.

### B2 — Delete the init-callback layer; own a deterministic Windows show sequence *(revised)*
Per Drew: the `onWindowFocus` / 2s-safety-net / `waitUntilReadyToShow`-callback machinery **is**
the complication, and the comments around it are suspect. We are not preserving it.
**Target (Windows):** a single, fully-awaited init chain we control —
`create window → performShow → applyState(collapsedShown) → presentInitialFrame()` — with no
focus dependency and no Timer. Pre-show config (`strategy.initialize`, `moveToDisplay`,
`beforeShow`, `setAsFrameless`) runs first; everything after `performShow` is a real awaited step
in `initialize()`, not inside an un-awaited callback.
**Decision:** Empirically probe what `waitUntilReadyToShow` actually does (one throwaway run with
logging) — *to know what to delete*, not to depend on it. If its callback can't give us a
deterministic "shown" point, stop routing show through it: call `performShow` ourselves on the
awaited path. The success criterion is that `onWindowFocus`, `_safetyNet`, `_firstShowHandled`,
and `_handleFirstShow` are **gone** and init still lands the full strip with no mouse-over. Delete
them in the same step that proves the thesis (step 2).

### B3 — Windows-first; keep the seam overridable, validate the rest later *(revised)*
`initialize()` is shared, and macOS/Linux currently lean on it (macOS `awaitReadyToShow` →
`unawaited` + deferred `performShow`; Linux X11 strut ordering via `afterWindowShown`). Per Drew
we are **not** gating this work on macOS/Linux validation.
**Decision:** Build and verify the new transition API + init chain on **Windows only**. Keep
`performShow` timing, `presentInitialFrame`, and `_applyReservation` as `@protected` override
seams so the other platforms attach later, and capture their known constraints (macOS deferred
show, Linux strut-before-map) as a short "Other platforms" section in the plan — to be scheduled
as separate work. Reducing platform divergence is the goal; achieving it everywhere is not in
this sprint's scope.

### B4 — `applyState` must absorb the display-change and font-size paths too
§3.5's trigger list (init/hover/collapse/show/hide) omits two existing geometry paths:
`didChangeMetrics`/`_onDisplayChanged` → `_doExpand/_doCollapse` (`window_service.dart:408`) and
`updateHeights(fontSizePx)` (`:215`). Leaving them as separate paths keeps two drifting routes —
the exact thing we're deleting.
**Decision:** display-change and font-size change both re-apply the **current** `StripState`
through `applyState`. Add them to the §3.5 diagram.

### B5 — `_applyReservation` must keep the AppBar `rcTop` feedback + reentrancy guard
`applyState` does `applySize` **then** `_applyReservation`, but today `_reserveCollapsedSpace`
itself calls `applySize` (`windows_window_service.dart:303`) *after* learning `rcTop` from
`ABM_QUERYPOS`. Two real things must survive: (a) the `_appBarBusy` reentrancy guard, and (b) the
`rcTop` the AppBar returns, which determines the y-origin. For a top-edge bar `rcTop` is normally
0 so apply-then-reserve works — but don't silently drop it.
**Decision:** `_applyReservation` is **pure reservation, no geometry** (the double-`applySize`
goes away). Assert/handle `rcTop == 0` for the top edge; if a display ever yields `rcTop != 0`,
fold it into the position passed to `applyState`'s `applySize`. Keep `_appBarBusy`. The public
`reassertAppBar` + `reRegisterReservation` hook collapse into `_applyReservation`, and
`onDisplayChangedExtra` funnels through `applyState` — no separate reposition path.

---

## §7 Open Questions — binding decisions

1. **StripState ownership → conventional Flutter MVC; normalise Model vs View state** (per Drew,
   supersedes my earlier "put it on WindowService"). Three layers:
   - **Model / Controller — `StripController` (a `ChangeNotifier`).** Owns the canonical
     `StripState` and *is* the transition API: `collapse()`, `expand()`, `hide()`, `show()`, plus
     reactive re-apply on display/font change (B4). It is the **single serialised entry point**
     (`AsyncGate`, last-wins — B1). It delegates OS geometry to `WindowService.applyState(s)` and
     notifies listeners of the settled state.
   - **OS executor — `WindowService.applyState(s)`.** Idempotent, stateless-of-intent: maps a
     state to geometry + reservation at the platform seam. Holds no "desired state" truth — the
     controller does.
   - **View — `TimelineStrip`.** Listens to the controller (`ListenableBuilder`/`AnimatedBuilder`),
     renders the current state, and runs **view-only** animation (`_hideAnim`, expansion height
     tween). Gestures call controller methods. It keeps *no* model state — `_isHidden` and the
     scattered booleans move into `StripState` on the controller.

   This is the normalisation Drew asked for: **model state** (which of the 3) lives in the
   controller; **view state** (animation values, hover visuals, ephemeral UI) stays in the widget.
   `ExpansionController` + the hide/show logic currently in `timeline_strip.dart` **collapse into
   `StripController`** (it already owns the executor/gate — rename/extend rather than add a 4th
   object). This also resolves OQ-6 cleanly: the controller owns truth; `_hideAnim` and the height
   tween are animators it drives, never independent sources of state.
2. **`presentInitialFrame` → `RedrawWindow(hwnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW)`,
   unconditional, last init step.** It's the minimal "paint now" that touches no geometry.
   `SWP_FRAMECHANGED` is heavier (non-client recompute, risks re-poking the AppBar) — keep as
   documented fallback only. Guard for null `hwnd` (FindWindow can fail) and log it. Conditional
   "did it land?" detection is unobservable from Dart — don't attempt it.
3. **`waitUntilReadyToShow`** → see **B2**. Blocking; confirm empirically, then restructure.
4. **AppBar lifecycle onto `_applyReservation`** → approved with **B5** constraints. shown ⇒
   register-or-reassert; hidden ⇒ dispose. Display-change re-reserves via `applyState`.
5. **WindowMode (reserved/overlay)** → **keep as a separate axis** that parameterises
   `_applyReservation`. Do not fold into the 3 states; it's orthogonal.
6. **ExpansionController / `_hideAnim`** → resolved by the MVC decision in (1): `ExpansionController`
   collapses **into** `StripController` (carrying its `AsyncGate`/executor role); `_hideAnim` and
   the expansion height tween stay **view-only animators** the controller drives. Truth lives only
   in `StripController.state`; nothing else decides geometry.

---

## Notes (non-blocking)

- §8 testing: the sliver fix is **manual-Windows-only** verifiable. Step 2's "validate sliver
  gone" gates on Drew's manual run, **not** green CI. Tests prove the state→geometry table and
  no-regression only — say so explicitly so we don't mistake green for fixed.
- Migration order §6 is good. Add "wire serialisation (B1)" to step 1, and keep
  `onWindowFocus`/safety-net until step 2's restructure (B2) lands the replacement signal — delete
  them in the same step that proves the thesis, not before.
- Honor Neo's owed cleanup: remove the two `actual window size=` getSize diagnostic logs.

**Hand-off:** @Neo *swe impl — Windows-first.
- **Step 1:** introduce `StripState` + `StripController` (MVC: ChangeNotifier owning state + the
  transition API, `AsyncGate`/last-wins per B1) + `WindowService.applyState` / `_applyReservation`
  / `presentInitialFrame` seams. No callers yet; `ExpansionController` is renamed/extended into
  `StripController`, not duplicated.
- **Step 2 (proves the thesis):** probe `waitUntilReadyToShow` once to know what to delete, then
  rebuild init as the deterministic awaited chain (B2) and **delete** `onWindowFocus`/`_safetyNet`/
  `_firstShowHandled`/`_handleFirstShow`. Manual-Windows gate: full strip on launch, no mouse-over.
- Then migrate hide/show/expand/collapse + display/font triggers (B4) onto the controller; retire
  the reassert hack; drop dead `resizeToMini/FullStrip`. Capture macOS/Linux constraints in a
  short "Other platforms" plan section (B3) for separate scheduling.
