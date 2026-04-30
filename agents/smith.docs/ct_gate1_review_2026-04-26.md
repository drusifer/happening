# Smith Gate 1 Review — Linux Click-Through Sprint
**Date:** 2026-04-26
**Status:** APPROVED with amendments

## Story Verdicts

| Story | Verdict | Notes |
|---|---|---|
| CT-01 | ✅ Pass | Clear, testable, user-focused |
| CT-02 | ✅ Pass | Correct consistency framing |
| CT-03 | ⚠️ Pass with fix | AC1 must remove internal API name; hover-to-focus ordering needed |
| CT-04 | ⚠️ Pass with fix | No "gtk-layer-shell" in user-facing text; inline not tooltip |
| CT-05 | ✅ Pass | Clean regression coverage |

## Required Amendments Before Architecture

### CT-03 AC1
**Current:** "When the strip transitions to focused mode (hotkey or hover trigger), `setIgnoreMouseEvents(false)` is called and clicks land on the strip."
**Fix:** Remove `setIgnoreMouseEvents(false)`. Write as user outcome: "When the strip transitions to focused mode, pointer events are delivered to the strip and controls respond to clicks."
**Heuristic:** H2 — Match Between System and Real World. Internal API names in acceptance criteria are implementation leakage.

### CT-04 — Inline text, no technical jargon
**Current:** Tooltip mentioning "gtk-layer-shell" and "XWayland."
**Fix:**
- Use **inline text** below the disabled option, always visible (not tooltip-only).
- **User-facing string:** *"Transparent mode is not available in this session. Start Happening from a native Wayland session to enable it."*
- No mention of gtk-layer-shell, XWayland, or GDK to the user.
**Heuristic:** H2 (no jargon) + H6 Recognition Rather Than Recall (always visible, not hover-to-discover).

## UX Question Answers

### Q1 — Tooltip vs inline for CT-04
**Answer: Inline, always visible.** Tooltips require hover-discovery. The explanation should be readable at a glance when the user opens settings. A disabled option with no visible reason violates H5 (Error Prevention) and H6 (Recognition Rather Than Recall).

### Q2 — Hover-to-focus reconsideration
**Answer: Yes, revisit. Hover + delay should be the primary focus trigger.**

Rationale: The strip's UX premise is glanceability without explicit navigation. Requiring a keyboard shortcut to interact with something you're already looking at increases cognitive load unnecessarily (H7 — Flexibility and Efficiency). Now that click-through is proven to work, the natural interaction is:
- **Hover over the strip for ~300ms → strip focuses, click-through disabled**
- **Move cursor away (or press Escape) → strip returns to idle, click-through re-enabled**
- **Global hotkey remains as secondary path** for keyboard-first users and explicit toggle

The 300ms delay prevents accidental activation while mousing over the strip to reach content below. This was the right deferral when click-through was unproven; now it's the right default.

Morpheus should design the focus trigger as: hover-primary + hotkey-secondary, both converging on the same `setFocused(true/false)` path.

### Q3 — Layer-shell hard vs soft gate
**Answer: Soft gate always.**

The app must always launch and be usable regardless of whether layer-shell is present. A missing optional feature must never prevent launch (H9 — Help Users Recover from Errors). Correct behavior:
1. Check for layer-shell at startup.
2. If absent: launch in reserved mode, transparent mode disabled in settings with CT-04 inline explanation.
3. Never show an error dialog or refuse to launch over a missing optional feature.

## State Saved
- context.md updated.
- current_task.md updated.
