# Cypher Context

## Current State (2026-06-09)

### F-31 Timestrip Hide/Collapse — IN PLANNING (stories drafted 2026-06-09)
- Collapse button on left edge; slide-left animation; mini-widget shows countdown + expand button
- Both countdown tap and expand button restore the full strip
- Linux strut released on collapse, re-acquired on expand
- Windows AppBar: pending OQ-F31-2
- Stories: `agents/cypher.docs/f31_timestrip_hide_stories.md`
- PRD: F-31 added to V2 table in `docs/PRD.md`
- **3 open questions for Drew (OQ-F31-1..3)** — blocks Smith Gate 1
- F-15 (Snooze/Focus) in V3 backlog superseded by F-31 (more specific + strut behavior); F-15 can be removed from backlog after F-31 ships

### F-30 Multi-Monitor Support — SHIPPED 2026-06-03 (per memory)
- All phases A+B+C2+D+E complete; 417 tests green; hardware-blocked C3/F1/F2; F3 docs ready
- PRD entry: present

### F-29 Astronomical Timeline Theme — SHIPPED 2026-05-24 (per memory)
- 372/372 green; Oracle doc pass (AST-E2) still listed as pending in old state — low priority reconcile

### F-28 Linux Reserved Space — DONE (code shipped 2026-05-18)
- Phase C (Trin UAT + Morpheus review) still technically pending — carried forward

### Send-to-Back (F-27) — COMPLETE 2026-05-14
- 266/266 green

### Dropped / Stale
- Click-through / F-26: DROPPED 2026-05-13, replaced by F-27

## Decision Log
- 2026-04-24: Drew accepted transparent pass-through as macOS approach (reversed 2026-05-13)
- 2026-04-25: Linux Wayland Simplification landed
- 2026-05-13: Click-through dropped; F-27 Send-to-Back added
- 2026-05-13: `WindowMode.transparent` → `WindowMode.overlay`; `WindowsWindowInteractionStrategy` → `ReservedWindowInteractionStrategy`
- 2026-05-16: F-28 sprint planned; Smith Gate 1 approved
- 2026-05-18: F-29 stories written; all OQs resolved
- 2026-05-29: F-30 Multi-Monitor stories drafted; 4 OQs resolved by Drew
- 2026-06-03: F-30 SHIPPED (per memory)
- 2026-06-09: F-31 stories drafted; 3 OQs raised for Drew (OQ-F31-1..3)

## Stale docs (low priority cleanup)
- `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md`
- `agents/cypher.docs/transparent_timestrip_requirement_2026-04-24T15:00.md`
- `agents/cypher.docs/transparent_timestrip_plan_Summary_2026-04-25T16:41.md`
- `agents/cypher.docs/transparent_timestrip_sprint_stories_2026-04-24T15:04.md`
- `agents/cypher.docs/linux_wayland_simplification_sprint_stories_2026-04-25T16:41.md`
- `agents/cypher.docs/linux_wayland_simplification_plan_Summary_2026-04-25T16:41.md`

---
*Last updated: 2026-06-09*
