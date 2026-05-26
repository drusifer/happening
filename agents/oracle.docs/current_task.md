# Current Task

## Groom Documentation for v0.5.1 — 2026-05-26
**Status**: DONE ✅

### Done
- [x] Updated root README.md with v0.5.1 status, F-27/F-28/F-29 milestones, and revised Architecture Overview (AstroDataService, SkyBody layers, GeoNames offline search, Send-to-Back mechanism).
- [x] Updated root USER_GUIDE.md with detailed Send-to-Back behaviors (10s timer, continuous lowering, non-intrusive focus).
- [x] Added USER_GUIDE.md Section 7 on the Astronomical Theme & Location Settings (sky gradients, celestial markers, offline computations, GeoNames local search setup).
- [x] Documented z-ordering refinements and locale-specific 12/24h formats in USER_GUIDE.md.
- [x] Resolved Windows compatibility issues in chat.py (UTF-8 encoding) and Makefile (bash check removal).
- [x] Archived 1,627 lines of CHAT.md into `agents/chat_archive/CHAT-ARCHIVE-20260526.md` and added dynamic summaries for v0.3.1, v0.4.0, and F-27/F-28/F-29 sprints.
- [x] Standardized structured TLDR blocks across 11 newly created or modified files in core astronomy, rendering layers, and window resize strategies.

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
