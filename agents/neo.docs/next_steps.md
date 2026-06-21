# Neo Next Steps — 2026-06-20 (updated)

## COLD-START RESUME ORDER
1. Read `agents/CHAT.md` bottom — last is Neo→Drew "Repro DONE ... Next: Step3 onWindowMoved re-pin".
2. Read `docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md` — THE source of truth (esp. §4.3 OS-move
   reconciliation, §6 migration steps 2-3). And `neo.docs/current_task.md` + `context.md`.
3. Read `docs/LESSONS.md` L-005, L-006 (+ DPI corollary).

## IMMEDIATE NEXT — AWAITING Drew's manual gate on SHOW
SHOW was converged onto the init path (showStrip = applyState(collapsedShown)+presentInitialFrame,
Windows override). 91 window tests green, analyze clean. Drew must `make run-windows` and test
hide->show: strip should now stay IN the strut (NOT drift to (0,73)). Scrape build.out GEO[] +Nms.

### IF manual gate PASSES (no drift):
- Convergence alone fixed it. The §4.3 onWindowMoved re-pin stays DROPPED (update plan: mark §2b
  decision validated). Then continue normalizing the rest:
  - **Hide**: `_hideStrip -> applyState(hidden)` (Windows override showStrip's sibling, e.g. hideStrip()).
  - **Expand/collapse**: route ExpansionController through applyState(expandedShown/collapsedShown)
    (Drew also saw expand strand below strut). Same converge-onto-init principle.
  - Then delete dead resizeToMini/Full, onHide/ShowStrip (plan §5). Keep GEO logging.
### IF manual gate STILL drifts:
- Empirically proves the ABM_REMOVE->ABM_NEW teardown itself relocates regardless of path (not the
  inverted order / missing present). ONLY THEN add the §4.3 onWindowMoved re-pin (plan §2b contingent),
  model relocation->move-event in FakeWin32Desktop + regression test (L-006). Discuss with Drew first.

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
