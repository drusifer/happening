# Smith Gate 1 — Send-to-Back Sprint Stories
**Date**: 2026-05-13
**Status**: Awaiting Smith review

---

## Sprint Goal

Remove all remnants of the click-through / pass-through feature (three failed implementation attempts) and replace with a single, cross-platform "Send to Back" behavior. The strip temporarily drops behind other windows so the user can interact with whatever was obscured, then auto-returns after 7 seconds.

---

## User Stories for Review

### US-STB-01 — Send the Strip Out of My Way
> As a user whose active window is being blocked by the timeline strip, I want to press a button to temporarily send the strip behind my other windows, so I can resize, click, or interact with whatever is behind it.

**Acceptance Criteria:**
- A "send to back" button is visible on the collapsed strip on all platforms (macOS, Linux, Windows)
- Pressing it immediately lowers the strip window behind all other windows
- The button shows an active/in-progress visual state while the strip is sent back
- After 7 seconds, the strip automatically returns to its always-on-top position
- If the user presses the button again while already sent back, the 7-second timer resets

---

### US-STB-02 — Strip Reliably Returns
> As a user who sent the strip to the back, I want it to automatically return to the top of the screen after a short time, so I don't have to manually bring it back or lose track of it.

**Acceptance Criteria:**
- Strip always auto-restores to always-on-top after exactly 7 seconds
- Timer starts the moment the button is pressed
- Visual state on the button clears when the strip restores
- Behavior is identical on all platforms

---

### US-STB-03 — No More Broken Pass-Through Mode
> As a user on any platform, I want the settings panel to not offer features that don't work, so I'm not confused by options that silently do nothing.

**Acceptance Criteria:**
- No "transparent pass-through" or "click-through" mode appears anywhere in the UI or settings
- `WindowMode.transparent` is removed; existing saved settings fall back gracefully to overlay mode
- All docs and tooltips describe the strip's behavior accurately (no references to click-through)

---

## What is NOT Changing (Smith to verify scope is correct)

- Visual transparency of the strip background — the strip still looks semi-transparent, users can still see through it. Only the click-through *input* behavior is removed.
- Reserved space mode on Windows and Linux — still available via settings; the ReservedWindowInteractionStrategy handles both platforms.
- macOS — overlay mode only (no reservation), same as today.
- The 7-second timer is fixed (not user-configurable) in this sprint. Configurable timer is a future enhancement if needed.

---

## Open Questions for Smith

1. **Button label / icon**: Should the button use a "send back" icon (e.g., layers-down arrow), or is the existing pass-through icon acceptable? Does the active state need an explicit countdown indicator, or is the button highlight sufficient?
2. **7 seconds**: Is this the right duration from a UX standpoint? Too short = strip returns before user finishes; too long = user forgets the strip is gone.
3. **Restore behavior**: When the strip auto-restores, should it regain OS focus, or just return to always-on-top without stealing focus from whatever the user was doing?
