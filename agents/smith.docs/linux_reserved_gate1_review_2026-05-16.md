# Smith Gate 1 Review — Linux Reserved Space Sprint
*2026-05-16*

## Verdict: APPROVED WITH AMENDMENTS

The feature direction is correct and necessary. Three stories cover the right surface:
startup reservation, display-change update, and Wayland fallback. No UX gaps.

---

## Amendments Required Before Implementation

### AC-L1-1 — Remove implementation term
**Current:** "…via `_NET_WM_STRUT_PARTIAL`"
**Change to:** "…the OS work area is updated so the strip height is excluded from the
area available to other windows."
Reason: AC should describe what the user observes, not how it is implemented.

### AC-L2-1 — Remove implementation term
**Current:** "…the strut property is re-set with the current collapsed height (logical pixels × DPR)."
**Change to:** "…the reserved band adjusts to match the strip's current collapsed height."

### AC-L3-1 — Remove implementation term
**Current:** "If `DISPLAY` env var is absent or `XOpenDisplay` returns null…"
**Change to:** "If screen-space reservation is unavailable in this session (e.g. Wayland),
the app starts normally without reserving space. A warning is written to the log."

---

## UX Notes (non-blocking)
- No user-visible indicator of strut status needed — the behavior is the indicator
  (other windows simply don't cover the strip). Correct call to keep it invisible.
- US-L3 Wayland fallback: confirm the warning is in the developer log only,
  not surfaced in the UI. Users running Wayland are unaffected; no error dialog needed.

---

## Approved Stories
- US-L1 ✅ (with AC-L1-1 amendment)
- US-L2 ✅ (with AC-L2-1 amendment)
- US-L3 ✅ (with AC-L3-1 amendment)
