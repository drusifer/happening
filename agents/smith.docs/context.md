# Smith Context

## Recent Decisions
- 2026-04-24: Approved transparent timestrip sprint stories with UX constraints.
- 2026-04-24: Approved transparent timestrip architecture with implementation notes.

## Key Findings
- Transparent timestrip UX:
  - Focus should be deliberate, not hover-only.
  - Primary focus path should be a global hotkey.
  - A small always-visible focus affordance is acceptable only if architecture can keep it clickable without blocking the rest of the strip.
  - macOS should hide reserved/statusbar mode rather than showing a disabled control.
- Gate 2 architecture review:
  - `WindowInteractionStrategy` plus `TimelineFocusController` preserves the approved mental model.
  - Linux transparent mode should remain hidden unless proven in a real session.

## Important Notes
- Idle transparent mode should pass clicks through timeline/event areas by default.
- Focused mode must have clear visual state and Escape dismissal.
- Settings labels should describe user outcomes rather than platform implementation terms.

---
*Last updated: 2026-04-24T15:09*
