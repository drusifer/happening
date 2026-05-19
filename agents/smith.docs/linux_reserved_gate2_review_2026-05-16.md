# Smith Gate 2 Review — Linux Reserved Space Architecture
*2026-05-16*

## Verdict: APPROVED

Architecture is sound. Platform-channel plugin + Dart orchestration is the correct
separation of concerns. No UX surprises.

---

## UX Review of Architecture Decisions

### Platform-channel plugin (no C++ in runner)
**Approved.** Runtime enable/disable of strut is correct — users can switch window mode
in settings, so the plugin must support `reserve()` / `release()` calls at runtime.
Embedding strut in the runner startup (as before) would not support runtime toggle.

### No `_NET_WM_WINDOW_TYPE_DOCK`
**Approved.** Confirmed this is what caused the black screen. Not setting it means
the window remains a normal EWMH window, which is correct: it's an overlay strip,
not a panel/dock. The strip behavior (always on top, frameless) is achieved via
`window_manager` calls, not window type. ✅

### Wayland silent fallback
**Approved.** No dialog, no toast — just a log warning. Users on Wayland see the same
behavior as today (strip floats on top, no strut). When we add Wayland strut support
in a future sprint, it's additive. ✅

### `release()` in `dispose()`
**Approved.** Ensures the reserved band is freed when the app exits, restoring the
work area for other processes. ✅

---

## One Note (non-blocking)
- The settings label for "reserved" mode should describe the outcome: "Reserve space at
  top of screen" rather than "Reserved mode." Verify this is already the case before
  shipping; if not, it's a label-only fix and does not block the sprint.

---

## Gate 2: APPROVED — proceed to Mouse sprint breakdown.
