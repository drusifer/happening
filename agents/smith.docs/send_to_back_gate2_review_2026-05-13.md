# Smith Gate 2 Review — Send-to-Back Architecture
**Date**: 2026-05-13
**Verdict**: APPROVED WITH NOTES

---

## What Gate 1 Required — Confirmed

| Gate 1 Requirement | Architecture Response | Status |
|--------------------|----------------------|--------|
| 10s timer (not 7) | `restoreTimeout = Duration(seconds: 10)` in TFC | ✓ |
| No focus-steal on restore | `restoreToFront()` calls `setAlwaysOnTop(true)` only — no `wm.focus()` | ✓ |
| New icon (`flip_to_back`) | Listed in `TimelineStrip` changes | ✓ |
| Re-press resets timer + visual flash | `_restartRestoreTimer()` on re-press; brief state-toggle confirmed | ✓ |
| Restore doesn't interrupt user | `setAlwaysOnTop(true)` only — verified in sequence diagram | ✓ |

All Gate 1 requirements are correctly reflected in the architecture. No regressions.

---

## UX Review of Architecture Decisions

### `HoverFocusController` deletion
**Approved.** `HoverFocusController` was only ever active in `usesTransparentFocusModel` mode. With transparent mode gone, it is inert dead code. Deleting it is correct — leaving it would be a H8 violation (unnecessary complexity). Neo must also remove its instantiation from `TimelineStrip.initState()`.

### `WindowMode.overlay` rename + silent settings migration
**Approved.** Silent fallback from `'transparent'` → `overlay` is the right call. The user should never see an error or migration prompt for an internal enum rename. H5 (Error Prevention): the design prevents a confusing "unknown setting" error on first launch after update.

### `isSentToBackNotifier` replaces `isFocusedNotifier`
**Approved.** The notifier name change is correct — `isFocused` was conceptually wrong for what this controller now does. The strip is either "sent back" or not; "focused" was a holdover from the transparent focus model.

### `setInteractionFocused` removal from `WindowService`
**Approved.** With no transparent mode, there is no concept of "window interaction focus" at the OS level. The method was a pass-through to a no-op in reserved mode. Removing it is clean.

---

## Implementation Notes (not blockers)

### Note 1 — `wm.lower()` must be verified before T-08 closes

The medium risk in the risk register is real. On Linux, `setAlwaysOnTop(false)` removes the `keep_above` hint but does NOT guarantee the window moves behind currently-focused windows — it stays at its current z-order level until another window is raised. Without `lower()`, the "send to back" effect may be invisible on some Linux setups.

**Required**: Neo must verify `wm.lower()` availability in `window_manager` v0.5.1 Linux plugin before T-08 is marked done. If absent, Neo must either implement the fallback (document that the user must click another window to fully lower the strip) or find an alternative via `gtk_window_lower()` through a platform channel.

### Note 2 — No user-initiated early restore (intentional, not a defect)

The architecture provides no way for the user to manually cancel the send-to-back before the 10s timer fires. The strip is behind other windows; the button is not reachable. The only restore path is the timer.

**Assessment**: This is an acceptable limitation for Sprint 1 of this feature. 10 seconds is generous enough that most users will complete their task and simply wait. H3 (User Control and Freedom) is only partially satisfied — but the auto-restore is itself the safety net. If user feedback indicates they want a shorter timer or an explicit cancel, that is a V2 enhancement.

**Do not add scope** to this sprint for early cancel. Document this limitation in the user guide.

---

## Gate 2 Decision

**`*user approve Gate 2`** — Sprint proceeds to Mouse for phase planning.

Architecture is correct, clean, and user-safe. The two notes above are implementation guidance for Neo, not blockers for planning.
