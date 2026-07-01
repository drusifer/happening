# Current Task — 2026-07-01

**Status:** macOS ASWebAuth compliance item — combined stories+arch doc READY, sending to Smith (single fast-track gate)

## What was done (2026-07-01)
- Fast-tracked per bloop rule #4 (small maintenance/compliance item, not a new feature)
- Combined with Morpheus's architecture into one doc: `docs/sprints/macos-aswebauth-oauth/MACOS_ASWEBAUTH_STORIES_ARCH_2026-07-01.md`
- 1 user story (US-AUTH-01), 5 AC — no PRD table change needed (compliance fix to existing F-02, not a new feature)
- 2 open risks flagged for Neo to spike before implementation (redirect URI client type; known plugin bug)

## Next action
- `@Smith *user review docs/sprints/macos-aswebauth-oauth/MACOS_ASWEBAUTH_STORIES_ARCH_2026-07-01.md` — single fast-track gate
- Smith approve → Mouse phase breakdown → Morpheus final review

## Previous: F-31 stories READY — OQs resolved (2026-06-09, shipped since)

## What was done (2026-06-09)
- Read requirement doc (`agents/nreq_timestrip_hide.md`) + codebase (timeline_strip.dart, linux_window_service.dart, countdown_display.dart)
- Identified F-31 as the next feature number (F-30 shipped 2026-06-03)
- Noted F-15 (Snooze/Focus) in V3 backlog is superseded by F-31
- Wrote 5 user stories with full acceptance criteria: `agents/cypher.docs/f31_timestrip_hide_stories.md`
- Added F-31 to PRD V2 table in `docs/PRD.md`
- Raised 3 OQs for Drew:
  - OQ-F31-1: Collapsed anchor position (top-left vs other)
  - OQ-F31-2: Windows AppBar release on collapse (yes/no)
  - OQ-F31-3: Persist hide state across restarts (yes/no)

## Next action (blocked on Drew OQ answers)
- Drew answers OQ-F31-1..3 → Cypher bakes answers into AC
- Send to `@Smith *user review agents/cypher.docs/f31_timestrip_hide_stories.md`
- Smith must approve → proceed to Morpheus arch

## Other pending PM work (carried forward)
- F-15 (V3 backlog): Remove/update once F-31 ships — F-31 is the concrete implementation of F-15
- F-28 Phase C (Trin UAT + Morpheus review still pending)
- F-29 Oracle doc pass (AST-E2) still pending
- Stale cypher.docs cleanup (low priority)

---
*Last updated: 2026-06-09*
