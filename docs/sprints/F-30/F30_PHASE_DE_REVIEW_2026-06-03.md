# Morpheus Code Review — F-30 Phase D + E (Settings UI + Indicator)
*Morpheus — 2026-06-03*

## Verdict: APPROVED — 1 cleanup recommendation for follow-up

Phase D adds the Display picker (D1) and "unavailable" fallback row (D2);
Phase E adds the on-strip `DisplayFallbackIndicator` (E1) with the auto-return
fade+slide animation (E2). The plumbing of `DisplayService` through
`main → HappeningApp → TimelineStrip → SettingsPanel` matches the C2
forward-looking Note 1 exactly. The widget separation is clean and tests cover
the contracts the arch doc cares about.

The Opacity-widget GTK regression was correctly avoided in E2 by using
`color.withValues(alpha: opacity)` instead of wrapping in an `Opacity` widget.
Memory hit applied as expected.

---

## Arch Alignment

| Arch Component | Implementation | Verdict |
|----------------|----------------|---------|
| SettingsPanel reads `DisplayService.availableDisplays` + writes via `setChoiceResolver` (arch §"SettingsPanel — Display section") | `_DisplaySection` consumes both; uses `FingerprintChoiceResolver(PersistedDisplayChoice.fromDisplay(d))` on tap | ✅ |
| Persisted choice survives reboot (arch §"Identity & Persistence") | `settingsService.update(chosenDisplay: choice)` writes through to settings.json — already roundtrip-tested in Phase B | ✅ |
| "Currently set: X — unavailable" row (arch §"Visibility of System Status") | `_FallbackRow` gated by `isInFallback && persisted != null`; format matches spec | ✅ |
| `DisplayFallbackIndicator` listens to DisplayService, renders icon on `isInFallback` (arch §"Phase E") | Implemented via `ListenableBuilder(listenable: Listenable.merge([displayService, _autoReturnController]))` | ✅ — also correctly merges the animation controller so animation ticks rebuild |
| Size = `min(14, stripHeight - 8)` (Smith Note A) | `_iconSize()` returns `stripHeight - 8` clamped at `14`; respects floor at `0.0` | ✅ |
| Placed left of gear with ≥8px gap (Smith Note 1 + Smith Gate 2 Note A) | TimelineStrip icon row: `SizedBox(width: 4)` siblings on each side + 4px own padding = ~8px effective gap; `DisplayFallbackIndicator` rendered conditionally only if `widget.displayService != null` | ✅ |
| Tooltip per spec | `Tooltip(message: 'Chosen display unavailable — showing on primary.')` | ✅ |
| Deep-link tap → open Settings + auto-scroll Display section (Smith Note C) | TimelineStrip owns `_displaySectionKey` GlobalKey, passes to SettingsPanel; `_openSettingsToDisplaySection` toggles Settings + `Scrollable.ensureVisible(_displaySectionKey.currentContext)` after a post-frame callback | ✅ |
| Auto-return fade + slide 600ms (Smith Note 4 / Gate 1 + arch §"Phase E2") | `AnimationController(duration: kFallbackIndicatorAnimationDuration)`; opacity via color alpha; 24px slide via `Transform.translate` | ✅ |
| Animation fires on AUTO_RETURNING transition only, not on IN_FALLBACK entry | `wasJustAutoReturned` is the single trigger; verified by dedicated test | ✅ |

---

## SOLID / Code Smells

### Single Responsibility ✅
- `DisplayFallbackIndicator` does one thing: render the on-strip cue + own its exit animation
- `_DisplaySection` does one thing: render the picker + persist + show the fallback advisory
- Both widgets compose `ListenableBuilder` rather than reimplementing observation

### Open/Closed ✅
- Adding a new label format (e.g., for accessibility) requires changing `_FallbackRow._persistedLabel` — local to the section
- Adding a new "advisory state" (e.g., "weak match") would add a new row inside `_DisplaySection.build`; no other surface affected

### DIP ✅
- Widgets depend on `DisplayService` (a ChangeNotifier abstraction) and `SettingsService`; both inject probes/events at construction time. Tests use stub probe/events, no platform plugins required.

### GTK Opacity Hazard — Correctly Avoided ✅
Memory [[feedback_opacity_gtk_regression]] flags that the `Opacity` widget breaks GTK keyboard focus when it wraps anything above/behind settings text fields. E2 uses `color.withValues(alpha: opacity)` on the `Icon`'s color directly — no `OpacityLayer` is created. Good catch and good fix.

### Minor — `onWeakMatch` callback lost on user-driven resolver swap
Trin Observation 1 (and Neo's own follow-up note) — when the user picks a different display in `_DisplaySection._chooseDisplay`, the new `FingerprintChoiceResolver` is built without an `onWeakMatch` sink. Weak-match warnings only fire on first boot.

**Severity:** Low. Weak-match is advisory; user is actively choosing a display, so a warning is less urgent than the boot-time case where the user didn't intend the fingerprint drift.

**Recommendation (deferred — not a D+E blocker):** Add a convenience method to `DisplayService`:

```dart
// DisplayService new constructor param (optional, defaults to null):
DisplayService({ ..., this.onWeakMatch });
final void Function(PersistedDisplayChoice, DisplayInfo)? onWeakMatch;

Future<void> setPersistedChoice(PersistedDisplayChoice? choice) async {
  await setChoiceResolver(
    FingerprintChoiceResolver(choice, onWeakMatch: onWeakMatch),
  );
}
```

Then `main.dart` constructs `DisplayService(... onWeakMatch: logWarning)` and `_DisplaySection._chooseDisplay` calls `displayService.setPersistedChoice(choice)` instead of constructing the resolver inline. This is option (b) from Trin's note — cleanest because the sink lives at the boundary where loggers are wired (main.dart), not in UI code.

**Status:** Filed as a Phase F polish task. Does not block D+E approval.

### Minor — `_DisplaySection` placement
The section appears as the last column in SettingsPanel, after `_AstroLocationSection` when astro theme is active. The sprint plan said "after Location" so this is correct. Smith Gate 2 didn't flag column ordering. **Acceptable.**

---

## Test Coverage Adequacy

13 new tests; comprehensive against the AC contract:

**Indicator (8 tests):**
- Invisibility / visibility binary states ✅
- Size clamp at both extremes (Smith Note A) ✅
- Tap callback ✅
- Full auto-return animation lifecycle (entry → exit → hidden) ✅
- Specifically: no animation on IN_FALLBACK entry (Smith Note A protection) ✅
- Listener cleanup on dispose ✅

**Display Section (5 tests):**
- Conditional rendering on `displayService != null` ✅
- All-displays-listed contract ✅
- On-tap persistence (both `setChoiceResolver` AND `settingsService.update`) ✅
- Fallback row absent/present binary ✅
- Fallback row text contains persisted label ✅

Out of scope for unit tests (correctly deferred to F30-F2 Smith real-app pass):
- Pixel-level legibility of icon at minimum strip height
- Full open+scroll cycle end-to-end (mounting TimelineStrip with CalendarController too coarse for unit tests)
- Wayland 7s polling SLA (Phase F)

---

## Suite Health

`make test V=-vv` → 417 passing + 1 pre-existing failing (`TimelineStrip Goldens S4-31: hover card follows mouse X`). Same pre-existing flake from C2; D+E added no new regressions.

---

## Forward-Looking Notes

### Note 1 — Wire `onWeakMatch` through DisplayService construction (deferred)
Per Trin Observation 1. Cleanest at Phase F or as a small interim cleanup once D+E lands.

### Note 2 — Indicator placement gap is implicit, not explicit
The ≥8px gap rule is satisfied by composition (4px padding + 4px sibling spacer). If TimelineStrip's icon row is ever refactored, the gap could drift. **Optional:** add an inline comment in `timeline_strip.dart` near the indicator placement noting the rule. Non-blocking.

### Note 3 — F30-F2 real-app UX pass should include
- Indicator pixel-level legibility at minimum strip height (Smith Note A follow-up)
- Full deep-link cycle (tap → open + scroll into view) on real input
- Auto-return animation aesthetic — does the 600ms fade + 24px slide read as "your display came back"?

---

## Phase D + E Sign-off

- Settings UI implements both pickers AND the unavailable advisory; persistence wired through SettingsService
- Indicator is small, listener-driven, GTK-keyboard-safe, and animates only on the expected transition
- Test coverage matches the testable surface; remaining gaps are Phase-F real-app concerns
- `onWeakMatch` follow-up is deferred but acknowledged
- F30 stack is now feature-complete pending: F30-C3 (Windows hardware), F30-F1 (multi-platform UAT), F30-F2 (Smith UX pass), F30-F3 (docs)

**APPROVED. Loop *impl F-30-D+E COMPLETE.**

---

*Reviewed: 2026-06-03 — Morpheus.*
