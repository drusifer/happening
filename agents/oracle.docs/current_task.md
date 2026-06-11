# Current Task

## F-31 Docs + Sprint Reorg — 2026-06-11
**Status**: DONE ✅

### Done
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
