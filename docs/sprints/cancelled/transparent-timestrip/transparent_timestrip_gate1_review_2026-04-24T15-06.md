# Transparent Timestrip Gate 1 UX Review

**Date:** 2026-04-24T15:06
**Persona:** Smith
**Gate:** Sprint Story Review
**Verdict:** Approved with UX constraints

## Review Summary

The stories solve the right user problem: users need the timeline to remain visible without blocking the app titlebars and controls behind it. The sprint should proceed to architecture, with the constraints below treated as acceptance criteria refinements.

## UX Constraints

### Focus Trigger
Use a two-path focus model:
- Primary: global hotkey, because pass-through idle mode means clicks may intentionally go to the app behind Happening.
- Secondary: a small always-visible focus affordance near the now/countdown cluster if the platform can keep that target clickable without blocking the rest of the strip.

Do not rely on hover-only focus. Hover can be accidental, and transparent pass-through mode needs a deliberate action.

### Idle Click Behavior
Default idle behavior should pass clicks through the timeline and events. Event cards, settings, refresh, and quit should require focused mode unless Morpheus confirms a tiny focus affordance can be isolated technically.

### Dismissal
Focused mode needs an obvious exit:
- Escape exits focus.
- Losing focus or a short inactivity timeout may exit focus.
- Settings panels and event details must not disappear while the user is actively interacting with them.

### macOS Setting Treatment
Hide reserved/statusbar mode on macOS. Showing a disabled option adds cognitive noise and invites users to debug an unavailable platform behavior. If explanatory copy is needed, put it in help/about text, not in the main control path.

### Transparency Range
Use a bounded slider with plain labels:
- More visible
- Balanced
- More transparent

Initial product range recommendation: 35%-75% idle opacity for timeline/event surfaces. The now indicator, countdown, and focus affordance should remain visually stronger and should not drop below the legibility floor chosen by the visual system.

## HCI Notes

- **Visibility of system status:** Focused vs idle state must be visually unambiguous.
- **User control and freedom:** Keyboard focus and Escape dismissal are required.
- **Error prevention:** Hide unsupported modes on macOS and any unsupported Linux session instead of offering broken choices.
- **Recognition rather than recall:** Settings labels should describe outcomes, not implementation terms like "pass-through."

## Gate Decision

Approved. Proceed to Morpheus architecture with the constraints above.
