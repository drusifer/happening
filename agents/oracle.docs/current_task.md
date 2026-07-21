# Current Task

## Makefile analyze/lint scope query — 2026-07-21
**Status**: DONE (100%)
- Confirmed mandatory analyzer roots are `lib` and `test`.
- Confirmed `integration_test` is conditional on directory existence after its approved deletion.
- Identified all affected current analyzer entry points: win-test, analyze (both OS branches), and
  lint-style. No product or build files changed.
- Details: `Makefile_Analyze_Scope_Summary_2026-07-21T17-22.md`.
- Next item: Trin verifies Neo's Makefile change preserves this contract across analyzer targets.

## Lunar-day sunset expected-behavior query — 2026-07-21
**Status**: DONE (100%)
- Traced the expected dusk target and prior regression harness without changing product code.
- Found that the exact May 22 amber->lunar-up dusk assertion was removed in commit `6b09cd9`.
- Documented current coverage gap and implementation mechanism in
  `Lunar_Day_Sunset_Expected_Behavior_Summary_2026-07-21T16-55.md`.
- Next item: Trin should compare the live failure to this specification and file the QA diagnosis;
  Neo/Morpheus can design a fix only if the user requests implementation.

## Groom pass 2 — reorg + archive + filenames — 2026-06-21
**Status**: DONE ✅
- [x] **CHAT.md archived/deduped**: a prior archive (CHAT-ARCHIVE-20260611.md, covers 2026-05-06→06-03)
  had been created but never removed from CHAT.md nor linked. Removed the 721 duplicated lines, added the
  missing top link + a "through 2026-06-03" summary. CHAT.md 1476→761 lines. Live tail = 2026-06-03→today.
- [x] **Reorg**: `git mv` the completed planning artifacts to `docs/sprints/window-convergence-2026-06/`
  (WINDOW_ENTRYPOINT_CONVERGENCE_PLAN, WINDOW_STATE_REFACTOR_PLAN, ..._REVIEW_2026-06-17, +
  app/test/core/window/windows_reservation_plan.md which was misplaced in the test tree).
- [x] **Removed scratch** debug logs from repo root: build-hide-show-expand-collapse-good.md,
  build-no-strut-issues.md, build-show-below-strut.out, build-still-below-strut.out, build.below.out.
- [x] **Filenames**: renamed all 25 remaining EN-DASH (`–`) filenames → `-` (git mv; quotepath=false to get
  literal UTF-8). 0 Windows-invalid filenames remain repo-wide.
- [x] **Stale memory**: `memory/project_expansion_controller.md` → `project_strip_controller.md` (rewritten
  to the converged truth); `memory/MEMORY.md` Key Files updated (applyState/StripController).
- ARCH.md version bumped 0.7→0.8 (date 2026-06-21).

## Groom arch docs for StripController convergence — 2026-06-21
**Status**: DONE ✅ (focused arch pass; remainder queued in next_steps)

### Done
- [x] `docs/ARCH.md` §6 rewritten: new "Unified Window-State Machine (StripController → applyState)"
  subsection (single applier, AsyncGate gate, reserve-before-position, transition dispatch). Fixed the
  stale Display/DPI paragraph (was "re-expand/re-collapse" + per-collapse `_reserveCollapsedSpace`; now
  "re-apply current StripState via applyState"). Noted hidden-pill honors idle transparency.
- [x] `docs/DECISIONS.md`: recorded **DEC-009** (converge all transitions onto applyState + StripController;
  ExpansionController/ResizeExecutor/PhysicalWindowState/performResize/_doExpand/_doCollapse deleted;
  onWindowMoved re-pin rejected). TL;DR updated.
- [x] `docs/EXPANSION_CONTROLLER.md`: added ⛔ SUPERSEDED banner (subsystem deleted; points to ARCH §6 + DEC-009).
- [x] Verified README.md + USER_GUIDE.md have NO stale internal window-arch refs (grep clean); user-facing
  behavior unchanged by the convergence, so no user-doc edits needed.

### Verified-stale but NOT yet groomed (see next_steps)
- `memory/project_expansion_controller.md` — describes the deleted subsystem.
- `docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md`, `WINDOW_STATE_REFACTOR_PLAN.md`,
  `WINDOW_STATE_REFACTOR_REVIEW_2026-06-17.md` — completed-sprint planning artifacts; candidates to move to
  `docs/sprints/` (the refactor they planned is now shipped).
- `docs/DECISIONS.md:118` / `docs/LESSONS.md` mention `_doExpand`/`_doCollapse`/`resizeToMini` — these are
  HISTORICAL records (frozen), left as-is by design.
- 25 tracked filenames with EN-DASH (`–`) in `calendar-threading/`, `linux-wayland-simplification/`,
  `agents/mouse.docs/` — Windows-invalid; will block future commits touching them.

## F-31 Docs, Goldens + USER_GUIDE Updates — 2026-06-11
**Status**: DONE ✅

### Done
- [x] USER_GUIDE.md updated with F-31 Timestrip Hide/Show features, arrow button controls, and countdown-tap restoration.
- [x] Embedded the 10 new screenshots provided by the user in `docs/Screen Shots/` (including light/dark hidden views) into relevant sections of `USER_GUIDE.md`.
- [x] Scaled down and optimized all large screenshots in `docs/Screen Shots/` to a maximum width of 1280px (saving over 17MB).
- [x] Created `F-31: timeline strip hidden mini widget (golden)` test and updated project goldens.
- [x] Fix broadcast stream issue on `_FakeClock` in golden tests.
- [x] PRD.md F-31 row updated to ✅ SHIPPED with corrected terminology (hide/show, not collapse/expand)
- [x] DECISIONS.md TL;DR updated; DEC-008 written (F-31 D2: Flutter-only animation, single OS resize)
- [x] docs/LESSONS.md created with L-001..L-004; merged from agents/oracle.docs/LESSONS.md (now removed)
- [x] Sprint docs reorg: all sprint-specific .md files moved from agent folders to docs/sprints/
  - docs/sprints/F-31/ (8 files)
  - docs/sprints/F-30/ (16 files)
  - docs/sprints/F-29/ (8 files)
  - docs/sprints/F-28/ (6 files)
  - docs/sprints/F-27-send-to-back/ (5 files)
  - docs/sprints/linux-wayland-simplification/ (20 files)
  - docs/sprints/linux-click-through-cancelled/ (5 files)
  - docs/sprints/transparent-timestrip-cancelled/ (16 files)
  - docs/sprints/calendar-threading/ (6 files)
- [x] task.md updated: F-31 source artifact paths corrected; Phase A+B marked DONE; Phase C status updated

## Groom Documentation for v0.5.1 — 2026-05-26
**Status**: DONE ✅

### Done
- [x] Build System & Versioning: Created single-source-of-truth version file (`app/assets/version.txt`) and `sync_version.py` propagation script. Streamlined variable definitions in `Makefile` and imported `Makefile.windows` on Windows. Patched `mkf.py` stream redirection to utilize standard `threading` cross-platform, resolving Windows `select` socket crashes. Migrated the POSIX GeoNames extraction pipeline to a pure, platform-agnostic Python script `fetch_cities.py`. Created a unified Python parser `print_help.py` to format targets identically across bash and PowerShell command environments.
- [x] Brand Consistency: Updated root `README.md`, `USER_GUIDE.md`, `docs/PRD.md`, `docs/ARCH.md`, `docs/DECISIONS.md`, and `docs/WINDOWS_BUILD_STRATEGY.md` to consistently refer to the app by its official full name **"What's Happening?"**.
- [x] Updated root README.md with v0.5.1 status, F-27/F-28/F-29 milestones, and revised Architecture Overview (AstroDataService, SkyBody layers, GeoNames offline search, Send-to-Back mechanism).
- [x] Updated root USER_GUIDE.md with detailed Send-to-Back behaviors (10s timer, continuous lowering, non-intrusive focus).
- [x] Added USER_GUIDE.md Section 7 on the Astronomical Theme & Location Settings (sky gradients, celestial markers, offline computations, GeoNames local search setup).
- [x] Documented z-ordering refinements and locale-specific 12/24h formats in USER_GUIDE.md.
- [x] Resolved Windows compatibility issues in chat.py (UTF-8 encoding) and Makefile (bash check removal).
- [x] Archived 1,627 lines of CHAT.md into `agents/chat_archive/CHAT-ARCHIVE-20260526.md` and added dynamic summaries for v0.3.1, v0.4.0, and F-27/F-28/F-29 sprints.
- [x] Standardized structured TLDR blocks across 11 newly created or modified files in core astronomy, rendering layers, and window resize strategies.
- [x] Updated Windows installation instructions in `README.md` to highlight the official Microsoft Store download link.

## F-28 Linux Reserved Space — Documentation — 2026-05-18
**Status**: DONE ✅

### Done (2026-05-18 hotfix session)
- [x] DEC-007 written in docs/DECISIONS.md: LinuxResizeStrategy / setResizable(true) fix
- [x] DECISIONS.md TL;DR updated with DEC-007 summary
- [x] LESSONS.md: GTK3 silently ignores gtk_window_resize on non-resizable windows

## F-28 Linux Reserved Space — Documentation — 2026-05-16
**Status**: DONE ✅

### Done
- [x] DEC-006 written in docs/DECISIONS.md (supersedes DEC-005)
- [x] DEC-005 marked superseded
- [x] DECISIONS.md TL;DR updated
- [x] LESSONS.md: window_manager.dock() stubs + left/right only finding recorded

### Previous — Send-to-Back Sprint — Phase H2 Documentation — 2026-05-14
**Status**: DONE ✅

### Done
- [x] LINUX_SIMPLIFICATION.md — already accurate (Send-to-Back sprint, Reserved strategy, file map)
- [x] ARCH.md — bumped to v0.7 / 2026-05-14; Section 6 + AOQ-8/AOQ-11 already correct
- [x] README.md — added Linux Simplification + Send-to-Back sprint entry; updated Hover arch note (HoverController → TimelineFocusController)
- [x] USER_GUIDE.md — added "Always-Visible Strip Buttons" section (Refresh, Send-to-Back, Settings, Quit); fixed stale Linux constraint-forcing troubleshooting note
