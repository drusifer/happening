# F-31 Code Review — Morpheus — 2026-06-11

**Verdict: APPROVED with follow-up items**

All critical functionality correct. Tests comprehensive. Platform hooks symmetric. No blockers.

---

## What was reviewed

- `app/lib/core/window/window_service.dart` — public API + virtual hooks
- `app/lib/core/window/linux_window_service.dart` — onHideStrip/onShowStrip
- `app/lib/core/window/windows_window_service.dart` — onHideStrip/onShowStrip
- `app/lib/features/timeline/timeline_strip.dart` — state machine + UI
- `app/test/core/window/window_service_test.dart` — Phase A tests
- `app/test/features/timeline/timeline_strip_hide_test.dart` — Phase B tests

---

## Strengths

- **WindowService API**: `prepareToHide / completeShow / resizeToMiniStrip / resizeToFullStrip` are clean delegating wrappers. Correct Template Method pattern.
- **Platform hooks**: Linux and Windows overrides are symmetric: `onHideStrip` releases reservation, `onShowStrip` re-acquires. No logic leak between layers.
- **Z-order fix**: `_HideButton` last in Stack children — correct and well-commented.
- **`_HideTrackingWindowService`** test stub: tracks all four hook calls cleanly. No mock framework overhead.
- **State machine**: `_hideStrip` / `_showStrip` sequence is correct — prepareToHide before animation, completeShow after, resizeToMiniStrip at anim-end, resizeToFullStrip at show-start. Send-to-back save/restore is symmetrically handled.
- **Settings-on-hide close**: `_isSettingsOpen = false` + `collapsed` signal fired before animation. Correct.

---

## Non-blocking findings (follow-up task recommended)

### A — Countdown logic duplicated in _buildMiniWidget (HIGH priority)

`_buildMiniWidget` (lines 735–788) and `_buildCountdownPositioned` (lines 876–925) contain nearly identical `StreamBuilder<DateTime>` trees computing `tickActive / tickNextOverlap / tickNextToStart / tickTarget / tickMode / countdown`. ~50 lines duplicated.

**Risk**: if countdown logic changes, one copy will be updated and the other forgotten.

**Recommended fix**: Extract a `_CountdownStreamBuilder` stateless widget that takes `events`, `clock`, `layout`, `flashNotifier`, `enableAnimations`, `fontSizePx`, `stripBg` and emits a `CountdownDisplay` subtree. Both call sites become a one-liner.

### B — CurvedAnimation gap (AC-F31-1-3) (LOW priority)

`_hideAnim` is a linear `AnimationController`. The spec says ease-in-out. However, the animation value is used only as a binary gate (`value < 1.0` → show mini), not as a tween of any visual property. So the curve gap has no visible effect in the current implementation. The strip snaps to mini immediately on hide (`_isHidden = true`), and returns to full 300ms after show starts.

If a future sprint adds a smooth width tween or opacity fade, the `CurvedAnimation` wrapper must be added then. Low urgency.

### C — Redundant inner GestureDetector on show button (LOW priority)

`_buildMiniWidget` wraps the entire Row in `GestureDetector(onTap: _showStrip)`, but the arrow_right button also has its own `GestureDetector(onTap: _showStrip)`. Flutter arena ensures only the inner fires, so no double-call. But it's dead code. Remove the inner GestureDetector (keep the outer).

### D — Duplicate `// ── Build` comment header (TRIVIAL)

Lines 561–562 have two identical section headers. Remove one.

### E — getMiniWidth magic numbers (LOW priority)

```dart
double getMiniWidth(double fontSizePx) =>
    fontSizePx * 6.0 + 12.0 + 8.0 + 24.0 + 16.0;
```

The four constants sum to 60.0 but their meaning is opaque. A brief inline breakdown comment would help: `// countdown_padding(12) + gap(8) + button(24) + button_padding(16)`.

### F — State fields declared mid-class (TRIVIAL)

`_isHidden`, `_preHideSentToBack`, `_hideAnim` (lines 280–282) are interleaved with layout/event fields. Group with other boolean state flags at top of `_TimelineStripState`.

---

## Decision

**APPROVED.** Items A–F are maintenance/readability items. Recommend a brief F-32 cleanup task for items A and C (the actionable ones). B, D, E, F can be deferred.
