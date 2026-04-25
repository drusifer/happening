# Transparent Timestrip Requirement

**Date:** 2026-04-24T15:00
**Persona:** Cypher
**Source:** Drew new requirement
**Status:** Drafted for Smith UX review and Morpheus feasibility review

## Product Assessment

This direction is product-sound. The core user problem is not "reserve pixels at the top of the desktop"; it is "keep the timeline always visible without getting in the user's way." If macOS reserved space is unreliable, transparent pass-through is the better product model because it preserves titlebar access while keeping the calendar glanceable.

## Requirement

Happening should support a transparent pass-through timeline mode:

- macOS uses transparent pass-through as the default and fixed window mode.
- Windows and Linux expose a setting that toggles between transparent pass-through mode and reserved statusbar mode when supported.
- Idle state renders the strip and event blocks largely transparent so users can see windows behind Happening.
- The now indicator, countdown, and persistent controls remain more opaque for legibility.
- Shadowing/depth treatment must communicate that Happening is layered above the desktop.
- A deliberate focus action changes Happening into an opaque, interactive state so users can open event details and use settings/refresh/quit.
- Settings include a transparency slider with guardrails so the UI cannot become unreadable.

## UX Questions For Smith

- What is the lowest-friction focus trigger that works across desktop platforms: hotkey, edge gesture, hover dwell, click target, tray/menu action, or a combination?
- Which controls should remain clickable in idle mode if pass-through is active, and which should require focused mode?
- Should macOS hide the reserved/statusbar mode setting or show it disabled with explanatory copy?
- What opacity range preserves titlebar readability behind the strip without making event blocks too faint?

## Acceptance Criteria Draft

- On macOS, users can interact with underlying titlebars/windows through the idle strip area.
- Idle transparency applies to the timeline background and event blocks, not to the primary now/countdown affordance.
- Focused mode is visually distinct, opaque enough for reading event details, and clearly reversible.
- Transparent mode setting persists on Windows/Linux.
- Reserved/statusbar mode is unavailable on macOS.
- The transparency slider persists and clamps to a legible range.

## Prior Context

- `docs/ARCH.md` currently documents solid backgrounds to avoid Linux compositor transparency bugs.
- Oracle lessons record Windows expanded-area transparency as acceptable where DWM compositing supports it.
- Prior team chat shows a previous click-through/static-window experiment was reverted because Linux support was unreliable, but macOS click-through was identified as a good fit.
