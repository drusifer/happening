# Current Task — 2026-05-18

**Status:** F-29 Astronomical Timeline Theme — stories written, awaiting gates

## What was done
- Probed sunrise-sunset.org API → confirmed solar-only (no lunar data)
- Wrote 4 user stories with full AC → `agents/cypher.docs/f29_astronomical_theme_stories.md`
  - US-F29-1: Location setup (OS geolocation + manual lat/lng fallback)
  - US-F29-2: Solar events on timeline (sunrise/sunset + civil twilight gradient)
  - US-F29-3: Lunar events on timeline (moonrise/moonset + moon phase badge)
  - US-F29-4: Theme selection (opt-in, persisted, scaffolds F-16)
- Added F-28 and F-29 entries to `docs/PRD.md` V2 table
- Identified 3 open questions (OQ-1 moon source, OQ-2 twilight depth, OQ-3 offscreen moon)

## Pending gates before sprint can start
1. Drew answers OQ-1, OQ-2, OQ-3 (see stories doc)
2. Smith HCI review of F-29 stories
3. Morpheus architecture (geolocator package, moon data source, gradient rendering approach)

## Previous — F-28 Linux Reserved Space Sprint
**Status:** Phases A+B+hotfixes DONE 2026-05-18; Phase C (Trin UAT + Morpheus review) PENDING
- PM actions F-28: PRD entry added today ✓; settings label outcome-language check (non-blocking)

---
*Last updated: 2026-05-18*
