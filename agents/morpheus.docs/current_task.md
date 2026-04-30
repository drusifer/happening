# Current Task

## Linux Click-Through Sprint Architecture — 2026-04-26
**Status**: COMPLETE ✅ — Sprint plan approved, Phase A handed to Neo

### Done
- [x] Reviewed CT stories and Smith Gate 1 amendments.
- [x] Wrote architecture: `agents/morpheus.docs/LINUX_CLICK_THROUGH_ARCH_2026-04-26.md`.
- [x] Smith Gate 2 approved with notes (exclusive_zone=0, CT-03 focus-release).
- [x] Reviewed Mouse sprint plan and approved it.
- [x] Handed Phase A to Neo.

### Next
- [ ] Review Phase A after Trin UAT.
- [ ] Review Phase B after Trin UAT.
- [ ] Review Phase C after Trin UAT (close sprint → Oracle).

## Linux Click-Through Research + Test App — 2026-04-26
**Status**: COMPLETE ✅

### Done
- [x] Read `window_manager` Linux plugin source — confirmed `setIgnoreMouseEvents` not implemented.
- [x] Read Windows `SetIgnoreMouseEvents` implementation — WS_EX_TRANSPARENT pattern.
- [x] Researched GDK3 `gdk_window_input_shape_combine_region` as the X11/XWayland/Wayland solution.
- [x] Created test app: `tools/click_through_test/` with custom `click_through_plugin.cc/.h`.
- [x] Added `make run-click-test` / `make build-click-test` Makefile targets.
- [x] Build verified clean (`flutter build linux --release` passes).
- [x] Research doc saved at `agents/morpheus.docs/LINUX_CLICK_THROUGH_RESEARCH_2026-04-26.md`.

### Next
- [ ] @Drew: run `make run-click-test` and smoke-test click-through toggle (open terminal behind, enable, click through it).
- [ ] If verified: implement integration path in main `app/` (copy plugin, update LinuxWindowInteractionStrategy, gate linuxTransparentSupported).



## Transparent Timestrip Architecture — 2026-04-24
**Status**: LOADED - READY FOR PHASE D/F REVIEW

### Done
- [x] Loaded Morpheus state and recent chat.
- [x] Consulted Oracle via chat for prior transparency/window lessons.
- [x] Reviewed Cypher stories and Smith Gate 1 review.
- [x] Mapped existing `WindowService`, resize strategies, settings service, settings panel, and timeline painter structure.
- [x] Wrote architecture plan: `agents/morpheus.docs/TRANSPARENT_TIMESTRIP_ARCH_2026-04-24T15:08.md`.
- [x] Smith Gate 2 approved architecture.
- [x] Mouse wrote `task.md` sprint board.
- [x] Reviewed and approved sprint plan.

### Next
- [x] @Neo completed Phase A — Capability Spike.
- [x] @Trin passed Phase A UAT.
- [x] Morpheus reviewed and approved Phase A.
- [x] @Neo completed Phase B — Settings Foundation.
- [x] @Trin passed Phase B UAT.
- [x] Morpheus reviewed and approved Phase B.
- [x] @Neo completed Phase C — Window Interaction Strategy.
- [x] @Trin passed Phase C UAT.
- [x] Morpheus reviewed and approved Phase C.

### Next
- [ ] @Neo begin Phase D — Focus Model.

### 2026-04-25 Load Checkpoint
- [x] Loaded recent chat and Morpheus state after `$bob-protocol init load morph`.
- [x] Observed Neo's later handoff: build fixed, sprint reconciled, tests/build passed, analyze initially blocked.
- [x] Observed later `make analyze` PASS with no issues found.
- [ ] If asked to proceed, review Phase D/F artifacts and decide whether to approve or route to Trin for verification.

### 2026-04-25 Linux/Wayland Simplification Review
- [x] Logged user request and consulted Oracle via chat.
- [x] Reviewed Linux native runner, CMake, window service, Linux resize/interaction strategies, settings mode gating, architecture docs, and prior Oracle lessons.
- [x] Checked current package/docs landscape for `window_manager`, Flutter Linux desktop support, and layer-shell options.
- [x] Reached recommendation: remove Linux native reserved-space code if product accepts transparent/non-reserving Linux behavior; do not chase Dart-only Wayland exclusive-zone replacement.
- [x] Wrote sprint architecture: `agents/morpheus.docs/LINUX_WAYLAND_SIMPLIFICATION_ARCH_2026-04-25T16:41.md`.
- [x] Smith Gate 2 approved architecture.
- [x] Reviewed Mouse sprint plan and approved it.
- [x] Handed off Phase A to Neo.
- [x] Trin passed Phase A UAT.
- [x] Morpheus reviewed and approved Phase A.
- [x] @Neo completed Phase B/C.
- [x] @Trin passed Phase B/C UAT.
- [x] Morpheus reviewed and approved Phase B/C.
- [x] @Trin completed Phase D automated checks where possible.
- [x] Morpheus reviewed Phase D outcome.
- [x] User completed X11/XWayland and native Wayland smoke enough to choose backend.
- [x] Morpheus approved Phase D for X11/XWayland Linux behavior with no native Wayland or Linux transparent support claim.
- [ ] Native Wayland and Linux transparent support remain future-sprint work, not current claims.

## Calendar Fetch Threading Review — 2026-04-17
**Status**: APPROVED

### Done
- [x] Reviewed Neo implementation diff.
- [x] Verified `_inFlightFetch` single-flight behavior.
- [x] Verified no queued follow-up state/drain loop.
- [x] Verified per-calendar fetches are sequential.
- [x] Verified Trin UAT accepted calendar scope.

### Caveat
- [ ] Full test suite still blocked by unrelated window binding initialization failures.

## Calendar Fetch Threading Architecture — 2026-04-17
**Status**: COMPLETE — handoff to Neo

### Done
- [x] Loaded Morpheus state and recent chat.
- [x] Consulted Oracle via chat.
- [x] Reviewed current `CalendarController` state and refresh callers.
- [x] Issued binding architecture: single-flight controller + per-calendar sequential queue.
- [x] Documented implementation constraints in `CALENDAR_FETCH_THREADING_ARCH_2026-04-17T19:59.md`.

### Handoff
- [ ] @Neo implement the documented architecture.
- [ ] @Trin verify ignored refresh behavior and sequential calendar queue tests after Neo.

## Linux Black Screen + Stuck Fetching Diagnosis — 2026-04-15
**Status**: IN PROGRESS 🔴 — debug logging added, awaiting log output from user

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
