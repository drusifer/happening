# Linux Click-Through Sprint Stories

**Date:** 2026-04-26
**Persona:** Cypher
**Sprint:** Linux Transparent Click-Through
**Status:** Ready for Smith Gate 1

---

## Context Summary

Research (2026-04-26) confirmed:
- `window_manager` does not implement `setIgnoreMouseEvents` on Linux — silently fails.
- **Native Wayland** click-through works via `gdk_window_input_shape_combine_region` → `wl_surface.set_input_region`. Confirmed on Mutter.
- **XWayland** click-through does NOT work — Mutter routes clicks at the Wayland surface level before checking any X11 input shape.
- Full solution requires **gtk-layer-shell** for positioning on native Wayland (replacing `window_manager` x/y calls, which don't work on Wayland).

---

## Sprint Goal

Make Linux transparent mode actually transparent — clicks pass through when idle — on Wayland-based desktops, without breaking the existing reserved-mode experience for XWayland or pure X11 users.

---

## Scope

### In Scope
- Runtime detection of native Wayland vs XWayland vs pure X11.
- Port `click_through_plugin` from test app (`tools/click_through_test/`) to `app/linux/runner/`.
- Wire `LinuxWindowInteractionStrategy` to GDK input shape channel.
- `gtk-layer-shell` optional CMake dependency for Wayland positioning.
- Remove forced `GDK_BACKEND=x11` for Wayland systems; let GTK choose backend automatically.
- `linuxTransparentSupported = true` only when native Wayland + layer-shell confirmed.
- Focus-lock disables click-through while user is interacting (existing `setFocused` path).
- Settings panel: transparent mode grayed out with explanation on XWayland.
- Existing tests pass; new smoke coverage for Wayland click-through.

### Out of Scope
- macOS or Windows changes.
- New focus trigger mechanisms (global hotkey already shipped in TT-D2).
- New UI features beyond what click-through requires.
- Support for non-Mutter Wayland compositors (design for it, but don't claim it).

---

## User Stories

### CT-01 — Clicks Pass Through the Idle Strip on Wayland

*As a Linux user on a Wayland compositor, when my timeline strip is idle (collapsed, transparent mode), I want clicks on the strip area to reach windows behind it, so I can use my application titlebars, resize handles, and desktop without fighting Happening.*

**Acceptance Criteria**
- On native Wayland with layer-shell present: idle/collapsed strip passes all pointer events through to windows below.
- Transparent mode setting is visible and selectable in the settings panel when the above conditions are met.
- Clicking through the strip reaches a terminal, file manager, or any window positioned behind it.
- No focus steal on pass-through clicks — Happening does not come to the foreground.

---

### CT-02 — Strip Stays Anchored at the Top of Screen on Wayland

*As a Linux user on Wayland, when transparent mode is active, I want the timeline strip to remain anchored at the top of the screen at its correct width and height, so it does not drift or reposition after enabling click-through.*

**Acceptance Criteria**
- On native Wayland: strip anchors to top edge of the primary monitor via gtk-layer-shell, full-width, at configured height.
- Window does not reposition itself when click-through is toggled on or off.
- Expand/collapse (hover card) still works without breaking layer-shell anchor.
- Position behavior matches the existing X11 reserved-mode experience from the user's perspective.

---

### CT-03 — Focusing the Strip Re-enables Pointer Events for Interaction

*As a user who wants to interact with the strip (open a hover card, change settings, refresh), I want focusing the strip to temporarily restore normal pointer event handling, so I can use controls and event details.*

**Acceptance Criteria**
- When the strip transitions to focused mode (hotkey or hover trigger), `setIgnoreMouseEvents(false)` is called and clicks land on the strip.
- Focused mode visually distinguishes from idle (existing focused-state visual behavior unchanged).
- Returning to idle mode re-enables click-through.
- Escape / clicking away / existing dismissal paths restore idle click-through.

---

### CT-04 — XWayland Users See a Clear, Honest Explanation

*As a Linux user running on a Wayland desktop but in X11/XWayland mode, when I open settings, I want transparent mode to be clearly unavailable with a plain explanation, so I understand why it's disabled and what I'd need to do to get it.*

**Acceptance Criteria**
- Settings panel shows transparent mode option as disabled on XWayland, with a tooltip or inline note: e.g. "Transparent mode requires native Wayland (gtk-layer-shell). Your session is running through XWayland."
- No runtime error or silent failure — the capability gate prevents the broken state silently swallowing `MissingPluginException`.
- Reserved/statusbar mode continues to work correctly for XWayland users.
- Pure X11 users (no Wayland compositor) also fall back to reserved mode with no click-through.

---

### CT-05 — Transparent Linux Mode Does Not Regress Reserved Behavior

*As a Linux user who relies on reserved/statusbar mode, when click-through code is added, I want my strip to continue working exactly as before, so I don't lose positioning, expand/collapse, or event display.*

**Acceptance Criteria**
- All existing tests pass (no regressions in `make test`).
- Reserved mode continues to function on XWayland and X11 after the native Wayland path is added.
- `make build-linux` and `make run-linux` still work with no behavioral change for non-Wayland users.
- New Dart/C++ code paths are guarded so they only activate when native Wayland + layer-shell are confirmed.

---

## Open UX Decisions for Smith

1. **Tooltip vs inline text for CT-04**: Should the XWayland "unavailable" explanation appear as a tooltip on hover, inline below the option, or in a help dialog?
2. **Focus trigger on Wayland**: The existing global hotkey path was implemented in TT-D2. Does Smith want hover-to-focus re-examined now that we know pass-through actually works on Wayland? (Previously hover-to-focus was deferred because click-through was unverified.)
3. **Layer-shell as hard dependency vs soft gate**: Should the app refuse to launch in transparent mode without layer-shell, or silently fall back to reserved? Product preference?

---

## Recommended Phase Structure (for Morpheus / Mouse)

| Phase | Scope |
|---|---|
| A — Detection + Plugin | Runtime Wayland detection; port click_through_plugin to app; wire LinuxWindowInteractionStrategy; update capability gate. |
| B — Layer-Shell Positioning | gtk-layer-shell optional dep; Wayland anchor replaces window_manager x/y; remove GDK_BACKEND=x11 for Wayland sessions. |
| C — Integration + Polish | Settings panel CT-04 explanation; full transparent mode smoke; test coverage; no-regression validation. |
