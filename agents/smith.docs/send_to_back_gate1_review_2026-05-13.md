# Smith Gate 1 Review — Send-to-Back Sprint
**Date**: 2026-05-13
**Verdict**: APPROVED WITH AMENDMENTS

---

## Story-by-Story Review

### US-STB-01 — Send the Strip Out of My Way
**Verdict**: Approved with note

Story is well-formed and user-centric. The mental model is clear.

**Note — H1 (Visibility of System Status):** The AC says "button shows an active/in-progress visual state" — this is correct but underspecified. The active state must communicate two things to the user:
1. The strip is currently hidden behind other windows (not just that an action was taken)
2. It will return on its own (i.e., they don't need to do anything)

A simple button highlight satisfies this if paired with a tooltip like "Strip is hidden — returns automatically." No countdown needed in this sprint.

**Note — "second press resets timer":** This is the right behavior, but the user won't know the timer was reset unless the button briefly pulses/flashes on re-press. Add to AC: visual feedback on re-press (e.g., brief flash of active state) to confirm the timer was reset.

---

### US-STB-02 — Strip Reliably Returns
**Verdict**: Approved with amendment — change 7 seconds to 10 seconds

**AMENDMENT REQUIRED**: 7 seconds is too short for real window management tasks (resize, find a buried window, drag). Nielsen's flow limit is 10 seconds — below that, users feel rushed. 10 seconds gives enough time to complete a typical adjustment without the user feeling abandoned.

H3 (User Control and Freedom): The user initiated the hide — the auto-restore should give them sufficient time to actually complete their task.

**Amended AC**: "Strip always auto-restores to always-on-top after 10 seconds" (not 7).

---

### US-STB-03 — No More Broken Pass-Through Mode
**Verdict**: Approved with note

Story goal is correct and important.

**Note — H8 (Aesthetic and Minimalist Design):** The AC references `WindowMode.transparent` (an internal enum name). Acceptance criteria should describe user outcomes, not internal symbols. Replace:
> "`WindowMode.transparent` is removed; existing saved settings fall back gracefully to overlay mode"

with:
> "Users with previously saved 'transparent' window mode settings are silently migrated to the overlay mode default on next launch — no error, no prompt."

This is testable from the user's perspective without exposing implementation detail.

---

## Open Questions — Answered

### Q1: Button label / icon
**Decision**: Use a NEW icon — do NOT reuse the old pass-through icon.

The old icon is mentally associated with "click-through" behavior in any user who used the previous mode. Reusing it would violate H4 (Consistency and Standards) by relinking a deprecated mental model.

**Recommendation**: A "send behind" icon — a window/layer with a downward arrow, or a layers icon with the top layer moving back. Material Design's `flip_to_back` icon is a strong fit. The button highlight alone is sufficient for active state in this sprint — no countdown indicator needed.

### Q2: Timer duration
**Decision**: 10 seconds, not 7.

7 is too tight for users adjusting windows (especially on slower systems or with motor difficulties). 10 seconds aligns with Nielsen's flow limit and gives users a realistic window to complete their adjustment. This is a fixed value for this sprint; if feedback shows users want shorter/longer, make it configurable in a future sprint.

### Q3: Restore behavior
**Decision**: Restore to always-on-top WITHOUT stealing OS focus.

`setAlwaysOnTop(true)` only — no `focus()` or `raise()`. The user is actively working in another window when the strip returns. Stealing focus would:
- Interrupt whatever they were typing (H3: User Control and Freedom)
- Cause keyboard events to land in the wrong window
- Feel jarring and unpredictable

The strip silently slides back to the top of the z-order. The user notices it returned visually; it does not demand attention.

---

## Scope Verification

The "not changing" items Cypher listed are correct:
- Visual transparency stays ✓ (this is unrelated to input behavior)
- Reserved space on Windows/Linux stays ✓
- macOS overlay-only stays ✓
- Fixed 10-second timer (amended from 7) for this sprint ✓

---

## Required Amendments Before Morpheus

1. **STB-01 AC**: Add "re-press briefly flashes active state to confirm timer reset"
2. **STB-02 AC**: Change "7 seconds" → "10 seconds" throughout
3. **STB-03 AC**: Remove `WindowMode.transparent` internal reference; replace with user-outcome language (see above)
4. **Icon**: `flip_to_back` or equivalent — do not reuse old pass-through icon
5. **Restore**: Explicitly state "restore does NOT steal OS focus" in STB-02 or STB-01 AC
