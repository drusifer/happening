# F-31 Timestrip Hide / Show Sprint Stories

**Feature:** F-31 — Timestrip Hide/Show  
**Status:** READY — OQs resolved → Smith Gate 1  
**Date written:** 2026-06-09  
**Source:** `agents/nreq_timestrip_hide.md`

---

## Feature Summary

Add a hide button on the left edge of the timestrip. When pressed, the strip slides to the left, contracting to a minimal widget that shows only the countdown timer and a show button. Clicking either the show button or the countdown restores the full strip. On Linux and Windows, screen-space reservation (strut / AppBar) is released while hidden and re-acquired on show. Always starts fully visible on launch.

---

## Resolved Open Questions

| OQ | Question | Answer |
|----|----------|--------|
| OQ-F31-1 | Collapsed anchor position | **Top-left** — mini widget stays at the top-left corner |
| OQ-F31-2 | Windows AppBar release | **Yes** — release on hide, re-acquire on show (same as Linux strut) |
| OQ-F31-3 | Persist state across restarts | **No** — always start fully visible |

**Terminology note:** Use **hide / show** for this feature. "Expand / collapse" is reserved for hover-card state and must not be mixed with this feature.

---

## User Stories

### US-F31-1 — Hide the Timestrip
> As a user, I want a hide button on the left edge of the timestrip so I can slide the strip out of view when I need the full screen.

**Acceptance Criteria:**
- AC-F31-1-1: A rectangular arrow button pointing **left** (←) is displayed at the far-left edge of the timestrip at all times while the strip is visible.
- AC-F31-1-2: Clicking the hide button triggers a slide-left animation during which the timeline panel contracts; when complete, the visible strip is a minimal widget at the top-left corner showing only the countdown timer and a show button.
- AC-F31-1-3: The animation duration is ≤ 300 ms and uses an ease-in-out curve.
- AC-F31-1-4: The hide button is visible and functional on all platforms (macOS, Windows, Linux).
- AC-F31-1-5: The hide button is visually distinct from all other strip controls (send-to-back, settings, refresh, quit). The hide button click/tap target is at least 24×24 px regardless of the button's visual size.

---

### US-F31-2 — Countdown Visible While Hidden
> As a user who has hidden the timestrip, I want to still see the countdown timer so I always know when my next event starts without showing the full strip.

**Acceptance Criteria:**
- AC-F31-2-1: In hidden state the strip displays exactly two elements: the live countdown and a rectangular arrow show button pointing **right** (→).
- AC-F31-2-2: The countdown continues to update every second while the strip is hidden — it is never paused or stale.
- AC-F31-2-3: The countdown uses the same color urgency rules as in the full strip (white → orange → red as time approaches).
- AC-F31-2-4: The mini widget is content-width (just wide enough to fit the show button and countdown text with standard padding) and anchored at the **top-left** corner of the display.
- AC-F31-2-5: The mini widget remains always-on-top — it does not go behind other windows on its own.

---

### US-F31-3 — Show (Restore) the Full Timestrip
> As a user, I want to click the countdown or the show button to restore the full timestrip.

**Acceptance Criteria:**
- AC-F31-3-1: Clicking the show button (→) triggers a slide-right animation that expands the strip back to its full width.
- AC-F31-3-2: Clicking anywhere on the countdown timer also triggers the same show animation.
- AC-F31-3-3: The show animation uses the same ≤ 300 ms / ease-in-out curve as the hide animation (mirror of AC-F31-1-3).
- AC-F31-3-4: After the strip is shown, it is in its normal fully-visible state (hover state reset to not-hovering; settings panel closed if it was open).
- AC-F31-3-5: The full hide/show cycle is repeatable without restarting the app.
- AC-F31-3-6: The strip always starts in fully-visible state on launch, regardless of state at last quit.

---

### US-F31-4 — Linux Strut Released While Hidden
> As a Linux user with screen-space reservation enabled, I want the reserved top-screen space freed when I hide the strip so maximized windows can use the full screen height.

**Acceptance Criteria:**
- AC-F31-4-1: When the strip is hidden on Linux and the strut is currently active, the strut is released (`undock()`) before or during the hide animation so maximized windows can expand to full height immediately.
- AC-F31-4-2: When the strip is shown on Linux, the strut is re-acquired (`dock()`) immediately after the show animation completes.
- AC-F31-4-3: If the strut was inactive when hide was triggered, no strut operation is attempted.
- AC-F31-4-4: Strut release/acquire is idempotent — toggling hide/show rapidly does not leave the strut in an inconsistent state.

---

### US-F31-5 — Windows AppBar Released While Hidden
> As a Windows user, I want the AppBar reservation released when I hide the strip, consistent with the Linux strut behavior.

**Acceptance Criteria:**
- AC-F31-5-1: On Windows, when the strip is hidden, the AppBar reservation is released (equivalent to Linux strut release in AC-F31-4-1).
- AC-F31-5-2: On Windows, when the strip is shown, the AppBar reservation is re-acquired (equivalent to AC-F31-4-2).
- AC-F31-5-3: On macOS there is no screen-space reservation mechanism — hide/show has no AppBar or strut side effects on macOS.

---

## Explicitly Out of Scope (F-31)

- Hiding the app entirely or minimizing to system tray.
- Keyboard shortcut to hide/show — can be added in a future sprint.
- Any change to the countdown timer format or urgency logic.
- Per-display or multi-monitor variants of hide behavior beyond what F-30 already delivered.
- The term "collapse" or "expand" in any user-facing label or code identifier for this feature (those terms belong to hover-card state).

---

## Implementation Notes for Morpheus

*(Non-binding; Morpheus will refine in arch phase.)*

- **Terminology**: All code identifiers should use `hide` / `show` (e.g. `_isHidden`, `_hideStrip()`, `_showStrip()`). Never use `collapse`/`expand` in this feature's code.
- **Button style**: Rectangular arrow buttons (← / →), not chevrons or icons. Should match the visual weight of the other strip buttons.
- **Animation**: `AnimationController` + `Tween<double>` on window width. Must coordinate with `ExpansionController` which already owns window resizing — likely needs a separate hide/show path that bypasses hover-driven expansion logic.
- **Strut hook (Linux)**: `LinuxWindowService` already has `_linuxDock.undock()` / `_reserveLinuxStrut()`. Hide should call `undock()`; show should call `_reserveLinuxStrut()`. Same pattern as `onWindowModeChanged`.
- **AppBar hook (Windows)**: `WindowsWindowService` (or equivalent) will need the same hook pair.
- **State**: A `bool _isHidden` flag in `_TimelineStripState` (or on a new `HideController`) drives the animation and controls visibility.
- **Mini-widget size**: Content-width only — let Flutter layout determine width from countdown text + button; then call `windowManager.setSize()` to match.
- **Top-left anchor**: When hiding, window X stays at 0 (left edge); width shrinks. When showing, width expands back to full.

---

*Cypher — 2026-06-09*
