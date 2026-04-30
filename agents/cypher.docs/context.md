# Cypher Context

## Recent Decisions
- Sprint 4 complete as of 2026-03-01. v0.1.0 shipped.
- Sprint 5 candidate scope remains S5-03 Multi-calendar, S5-04 Collision Detection, and S5-05 Themes.
- 2026-04-24: Drew accepted a new direction for macOS window behavior: stop trying to reserve desktop space for the timestrip and use transparent pass-through behavior so titlebars behind the strip remain visible and usable.
- 2026-04-25: Drew requested Linux/Wayland simplification. Product decision: Linux should move toward transparent/non-reserving behavior where validated; native reserved-space panel behavior is no longer the preferred Linux product path.

## Key Findings
- Product state restored on 2026-04-24T14:45:
  - Last active PM work is Sprint 5 planning.
  - Sprint 5 assessment exists at `agents/cypher.docs/sprint5_assessment.md`.
  - Product planning is waiting on Drew answers for click-to-expand, macOS/Windows timeline behavior, and multi-calendar UI placement.
- Transparent pass-through requirement drafted:
  - PRD updated with F-26 and US-06.
  - Detailed PM note saved at `agents/cypher.docs/transparent_timestrip_requirement_2026-04-24T15:00.md`.
- Transparent timestrip sprint stories drafted for Bloop planning:
  - Stories saved at `agents/cypher.docs/transparent_timestrip_sprint_stories_2026-04-24T15:04.md`.
  - Sprint goal focuses on non-blocking transparent pass-through behavior with platform-specific mode availability.
- Linux Wayland Simplification sprint stories drafted:
  - Stories saved at `agents/cypher.docs/linux_wayland_simplification_sprint_stories_2026-04-25T16:41.md`.
  - Sprint goal removes Linux native reserved-space behavior and keeps Linux transparent support behind real-session validation.

## Important Notes
- All PRD MVP plus most V2 features are recorded as shipped in prior PM state: F-01-F-08, F-13/F-14, and F-20-F-25.
- Before making major Sprint 5 product decisions, consult Oracle for historical context.

- 2026-04-26: Linux click-through sprint stories drafted.
  - Research confirmed native Wayland click-through works; XWayland does not.
  - Full solution requires gtk-layer-shell for positioning.
  - Stories saved at `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md`.
  - 5 stories: CT-01 (click-through), CT-02 (layer-shell anchor), CT-03 (focus lock), CT-04 (XWayland fallback UX), CT-05 (no regression).
  - 3 open UX questions for Smith: tooltip vs inline, hover-to-focus revisit, hard vs soft layer-shell gate.

---
*Last updated: 2026-04-26*
