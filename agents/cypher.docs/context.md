# Cypher Context

## Project: Happening
- Multiplatform always-on-top horizontal timeline strip showing today's Google Calendar events
- Target users: ADHD / event-based thinkers
- Tech: Flutter + Google OAuth + Google Calendar API v3
- PRD written: docs/PRD.md (v0.1, Draft)

## Key Decisions Made
- MVP is read-only (no event creation/editing)
- Always-on-top floating window (not OS taskbar widget) — OQ-4 unresolved
- Countdown displayed prominently near Now indicator
- Now indicator fixed on left-third; events slide left in real time
- Proportional spacing between events

## Open Questions — ALL RESOLVED (Drew, 2026-02-26)
- OQ-1: DPI-adaptive strip height ✅
- OQ-2: All-day events NOT displayed ✅
- OQ-3: Celebratory state when day is done ✅
- OQ-4: Floating window (KISS) ✅
- OQ-5: Open source ✅

## New Features Added by Drew
- F-14 (V2): Hover detail + video call links
- F-19 (V3): Collision detection for overlapping events
