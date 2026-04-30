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
- 2026-04-25 Linux Wayland Simplification:
  - Gate 1 stories approved: simplify Linux by dropping native shell-reservation behavior and hiding unsupported transparent mode.
  - Gate 2 architecture approved: remove X11/layer-shell reservation path; real-session proof required before Linux transparent support claims.

## Important Notes
- Idle transparent mode should pass clicks through timeline/event areas by default.
- Focused mode must have clear visual state and Escape dismissal.
- Settings labels should describe user outcomes rather than platform implementation terms.

- 2026-04-26: Linux click-through sprint Gate 1 approved with amendments.
  - CT-03 AC1: remove internal API reference `setIgnoreMouseEvents`; write as user outcome.
  - CT-04: inline text (not tooltip), no "gtk-layer-shell" or "XWayland" in user strings. Proposed text: "Transparent mode is not available in this session. Start Happening from a native Wayland session to enable it."
  - UX decisions: hover+300ms delay is primary focus trigger; hotkey is secondary. Soft gate for layer-shell.
  - Full review: agents/smith.docs/ct_gate1_review_2026-04-26.md

---
*Last updated: 2026-04-26*
