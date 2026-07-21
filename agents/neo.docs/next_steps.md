# Neo Next Steps — 2026-07-21

## Makefile lint scope

No Neo work remains. Trin should run the full `make lint` gate; it should now
analyze `lib test` and skip the deliberately absent `integration_test` tree.
If that directory is restored later, it automatically re-enters analyzer scope.

## Lunar-day sunset transition regression

No Neo work remains. Trin should independently review the endpoint-wise
brightness selection, rerun the focused matrix, and choose any broader QA gate
appropriate for the product change. If QA finds a failure, resume from
`Lunar_Transition_Merge_Fix_Summary_2026-07-21T17-10.md` without changing the
matrix expectations.

# Neo Next Steps — 2026-07-09 (historical)

## hide-after-display-reapply strand bug — DONE. One flagged follow-up (not urgent):
`WindowService._reapplyCurrentState()` can't distinguish `hidden` from `collapsedShown` (both have
`isExpanded == false`) — a display/font change while legitimately hidden would force the strip back
to shown. Not reproduced by Drew's repro (strip was shown at the time), so left alone. If picked up:
give WindowService visibility into StripController's actual hidden state so reapply can no-op.
See current_task.md 2026-07-09 #2 section for full root-cause writeup.

## sync_version.py build-suffix bug — DONE, no follow-up required
Fixed + tested (see current_task.md 2026-07-09 section). One optional, non-urgent item: check
`update_snapcraft()` in `agents/tools/sync_version.py` for the same `[\d\.]+`-doesn't-allow-`+`
pattern if a snapcraft version ever needs a build suffix — untested, no known symptom.

# Neo Next Steps — 2026-07-08 (historical; see top for latest)

## Judge loop + lint remediation DONE — nothing owed by Neo
BUG-1 fixed and verified in `session_trace.py`. Bob owns BUG-2/3/4 next
(`agents/smith.docs/bugs.md`). If a cold start resumes here for the judge loop specifically:
check `agents/smith.docs/trace_eval.md` for loop iteration count before redoing any analysis.

---

# Neo Next Steps — 2026-07-01 (prior)

## macOS ASWebAuth (*bloop impl) — HANDED OFF to Trin for Phase C UAT
Phase A+B done (see current_task.md 2026-07-01 section). Trin: run/verify AC-1..6, especially AC-6
(unit-tested, but confirm no regression manually if possible) and the known Chrome-default-browser
plugin bug (flag if it manifests; can't be caught by unit tests). Then Morpheus final review.
This is a small parallel track — does NOT block or change F-31 pickup below.

## F-31 / WINDOW CONVERGENCE — untouched by the above, still the primary board. COLD-START RESUME ORDER
1. Read `agents/CHAT.md` bottom — last is Neo→Drew "Repro DONE ... Next: Step3 onWindowMoved re-pin".
2. Read `docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md` — THE source of truth (esp. §4.3 OS-move
   reconciliation, §6 migration steps 2-3). And `neo.docs/current_task.md` + `context.md`.
3. Read `docs/LESSONS.md` L-005, L-006 (+ DPI corollary).

## WINDOWS CONVERGENCE: DONE + VALIDATED + COMMITTED (e4100fc, cb8c1e5, 513d928).
Every Windows entrypoint (init/show/hide/expand/collapse/display/font/reassert) routes through
applyState. refresh=calendars-only. Validated by GEO logs (all (0,0), no drift). Re-pin dropped.

## NEXT PICKUP — Linux/macOS show/hide convergence (DO THIS ON A LINUX/MAC MACHINE, per Drew):
Base `showStrip`/`hideStrip` (window_service.dart ~430/442) still use resizeToFullStrip/resizeToMiniStrip
+ onShow/HideStrip — the only un-converged path, kept because Linux strut lives in onShow/HideStrip.
- Converge: give Linux/macOS an applyState-based show/hide (likely via applyReservation override for
  Linux strut, mirroring Windows AppBar), then retire resizeToFull/Mini + onShow/HideStrip + prepareToHide/
  completeShow. MUST gate on the real Linux + macOS desktops (strut/Spaces behavior only shows there).
- Also deletable then: Windows onShowStrip/onHideStrip overrides (already DEAD in prod — showStrip/
  hideStrip bypass them; only base path + tests still reference).
- Optional structural cleanup (no behavior change): fold ExpansionController into StripController (§4.1);
  wire StripController instead of calling applyState directly. Not required for correctness.

## GOTCHAS (still apply)
- mkf tail-printer crashes on '→' (cp1252) in build.out tail (exit 2) but the run completes. Avoid →
  in test names/reason strings; scrape build.out directly. make chat MSG hard limit 256 chars.
- Run `make` from REPO ROOT (PowerShell `cd app` breaks `make chat`; use `make -C <root>`).
- StripController (strip_controller.dart) exists but still NOT wired to callers — showStrip() is an
  interim that mirrors init directly (init also calls applyState directly, not via controller).

## WHERE WE ARE
The window-state refactor's init bug chain is fixed; now CONVERGING all window entrypoints onto the
single `applyState` applier so every transition behaves identically (kills the recurring
below-strut bug class). Convergence step 1 DONE.

### Root cause finally nailed (build.below.out 2026-06-19 22:55, +Nms probes)
- We set window (0,0); Windows ASYNC-relocates it to (0,73) ~150ms later (outside AsyncGate).
- Fires ONLY on ABM_REMOVE→ABM_NEW re-registration while window at (0,0). NOT on fresh init, NOT
  when already at (0,73). = Drew's ABM_REMOVE instinct.

### Fixes already in (Windows init path, all green +89 window / +190 timeline)
- applyState: reserve FIRST (applyReservation returns Offset? origin), THEN applySize at that origin.
- applyReservation: shown→register-if-needed + reserveTopBand (NO teardown); hidden/overlay→dispose.
- _bandHeightPx = (h*dpr).CEIL() — DPI-rounding safe (band ≥ window physical height). L-006 corollary.
- presentInitialFrame: SHRINK-settle (h-1→h, stays in band) + pin origin; deferred to post-first-frame
  via addPostFrameCallback (init runs before runApp → no frame yet).
- FakeWin32Desktop (test) models the relocation rule (window taller than band → push to band; DPI-aware
  ceil) — regression tests PROVEN to fail on the bug. THIS is how we test OS behavior (L-006).
- probeGeometryLater(): +150/500/1200ms position samples; disabled under FLUTTER_TEST. KEEP all GEO
  logging (Drew directive — feedback_keep_debug_logging.md).

### Convergence STEP 1 DONE
- Refresh button → calendars-only: dropped reassertAppBar (band-aid). timeline_strip ~1011.
- _IconButton → StatefulWidget with press feedback (AnimatedScale 0.86).

## NEXT STEPS (plan §6)
- **AWAIT Drew's refresh test** (should NOT strand strip; button depresses) — confirms ABM_REMOVE theory.
- **STEP 2**: converge hide/show. `_hideStrip→controller.hide()→applyState(hidden)`,
  `_showStrip→controller.show()→applyState(collapsedShown)`. Delete resizeToMini/Full + onHide/ShowStrip.
  Hide becomes the ONLY ABM_REMOVE.
- **STEP 3**: add onWindowMoved re-pin (re-add WindowListener — APPROVED) for the hide→show teardown
  relocation. Model relocation→move-event in FakeWin32Desktop + regression test (L-006). Compare vs
  CURRENT reserved origin, gate-aware (don't fight display-change / in-progress transitions).
- **STEP 4**: converge expand/collapse + display/font through controller; fold ExpansionController in;
  delete _doExpand/_doCollapse/performResize; onWindowModeChanged→applyState; delete reassertAppBar.
- **STEP 5**: cleanup dead executor; keep GEO logging.
- DEFERRED (separate task): animated window resize (build into applyState later — Drew "would be nice").

## GOTCHAS
- Run from REPO ROOT: `make win-test FILE=test/core/window/` (analyze+test, no ulimit). Scrape build.out
  for GEO[]/+Nms lines. macOS/Linux convergence deferred (Windows-first, review B3).
- StripController exists (app/lib/core/window/strip_controller.dart) but is NOT wired to callers yet —
  step 2-4 wire it. ExpansionController still drives expand/collapse for now.
- make chat MSG hard limit 256 chars — draft ≤230 + count BEFORE sending (recurring mistake).
