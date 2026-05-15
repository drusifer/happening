# Cypher Context

## Current State (2026-05-13)
- **Click-through / pass-through: DROPPED.** Three implementation attempts failed or were too complex. Feature is being replaced with "send to back."
- **Send-to-Back (F-27)**: Cross-platform. Button lowers window behind other apps, 7-second timer auto-restores. No platform-specific code needed.
- **Reserved mode**: Linux + Windows retain screen-space reservation via `ReservedWindowInteractionStrategy` (renamed from `WindowsWindowInteractionStrategy`).
- **macOS**: Overlay only (`MacOsWindowInteractionStrategy`, no reservation).
- **Architecture**: `BaseWindowInteractionStrategy` → `MacOs` (macOS) + `Reserved` (Linux/Windows). `sendToBack`/`restoreToFront` in base.

## Decision Log
- 2026-04-24: Drew accepted transparent pass-through as macOS approach.
- 2026-04-25: Linux Wayland Simplification landed — removed GTK click-through plugin.
- 2026-05-13: Drew dropped transparent click-through entirely. All pass-through APIs to be deleted. Send-to-back replaces the feature on all platforms.
- 2026-05-13: `WindowMode.transparent` → `WindowMode.overlay`. `WindowsWindowInteractionStrategy` → `ReservedWindowInteractionStrategy` (shared by Linux + Windows).

## Stale docs (to delete in T-01)
- `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md`
- `agents/cypher.docs/transparent_timestrip_requirement_2026-04-24T15:00.md`
- `agents/cypher.docs/transparent_timestrip_plan_Summary_2026-04-25T16:41.md`
- `agents/cypher.docs/transparent_timestrip_sprint_stories_2026-04-24T15:04.md`
- `agents/cypher.docs/linux_wayland_simplification_sprint_stories_2026-04-25T16:41.md`
- `agents/cypher.docs/linux_wayland_simplification_plan_Summary_2026-04-25T16:41.md`

## Important Notes
- MVP + most V2 features shipped in prior sprints (F-01–F-08, F-13/F-14, F-20–F-25).
- `docs/PRD.md` needs update: remove F-26, rewrite US-06, add F-27.

---
*Last updated: 2026-05-13*
