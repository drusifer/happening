# Cypher Context

## Current State (2026-05-29)

### F-30 Multi-Monitor Support — NEW (stories drafted 2026-05-29)
- Single strip, single user-chosen display (multi-strip / cursor-follow OUT of scope)
- Per-monitor DPI respected
- Hot-plug: auto-fallback to primary on disconnect, auto-return on reconnect
- Linux strut (F-28) generalized to chosen display
- Underlying packages already present: `screen_retriever`, `window_manager`
- Stories: `agents/cypher.docs/f30_multi_monitor_stories.md`
- PRD: F-30 added to V2 table in `docs/PRD.md`
- 4 open questions for Drew (OQ-1..4); blocks Smith + Morpheus gates

### F-29 Astronomical Timeline Theme — SHIPPED 2026-05-24 (per memory)
- Per auto-memory: 372/372 green; arc-based lunar bodies, astro tooltips, event blocks lower-half + opaque, directional shadows
- Oracle doc pass (AST-E2) pending
- PM follow-up: verify against current code before treating F-29 backlog items as live

### F-29 historical scope (stories written 2026-05-18)
- Opt-in "Astronomical" theme that pins sunrise, sunset, moonrise, moonset to the timeline
- Location: OS geolocation (geolocator package) with manual lat/lng fallback
- All astronomical data (solar + lunar): **Dart astronomy library** — fully offline, no external APIs
- Location: `geolocator` Flutter package + manual lat/lng fallback
- Day/night gradient: civil twilight begin → sunrise → day → sunset → civil twilight end → night
- Moon phase: 8-phase model (new/waxing-crescent/Q1/waxing-gibbous/full/waning-gibbous/Q3/waning-crescent)
- Stories: `agents/cypher.docs/f29_astronomical_theme_stories.md`
- PRD: F-29 added to V2 table in `docs/PRD.md`
- Next gate: Smith HCI review, then OQ-1 resolution, then Morpheus arch

### F-28 Linux Reserved Space — DONE (code shipped 2026-05-18)
- Phases A+B+hotfixes complete; 276/276 tests green; build passing
- Phase C (Trin UAT + Morpheus review) still pending
- PM action remaining: update PRD to confirm F-28 shipped (PRD entry added today)

### Send-to-Back (F-27) — COMPLETE 2026-05-14
- 266/266 green; all phases done

### Dropped / Stale
- Click-through / F-26: DROPPED 2026-05-13, replaced by F-27 Send-to-Back
- `docs/PRD.md` F-26 reference: already removed

## Decision Log
- 2026-04-24: Drew accepted transparent pass-through as macOS approach (reversed 2026-05-13)
- 2026-04-25: Linux Wayland Simplification landed
- 2026-05-13: Click-through dropped; F-27 Send-to-Back added
- 2026-05-13: `WindowMode.transparent` → `WindowMode.overlay`; `WindowsWindowInteractionStrategy` → `ReservedWindowInteractionStrategy`
- 2026-05-16: F-28 sprint planned; Smith Gate 1 approved
- 2026-05-18: F-29 stories written; all OQs resolved: Dart astro library for lunar, civil twilight gradient, always-on badge, geolocator package for location UI
- 2026-05-29: F-30 Multi-Monitor stories drafted; explicit scope guard against multi-strip and cursor-follow; 4 OQs raised for Drew

## Stale docs (low priority cleanup)
- `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md`
- `agents/cypher.docs/transparent_timestrip_requirement_2026-04-24T15:00.md`
- `agents/cypher.docs/transparent_timestrip_plan_Summary_2026-04-25T16:41.md`
- `agents/cypher.docs/transparent_timestrip_sprint_stories_2026-04-24T15:04.md`
- `agents/cypher.docs/linux_wayland_simplification_sprint_stories_2026-04-25T16:41.md`
- `agents/cypher.docs/linux_wayland_simplification_plan_Summary_2026-04-25T16:41.md`

---
*Last updated: 2026-05-29*
