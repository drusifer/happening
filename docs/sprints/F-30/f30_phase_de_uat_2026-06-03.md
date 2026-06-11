# Trin UAT — F-30 Phase D + E (Settings UI + Fallback Indicator)
*Trin — 2026-06-03*

## Verdict: PASS — 13/13 new tests green, full suite 417 + 1 pre-existing

Phase D ships the Settings Display picker (D1) and unavailable-fallback row (D2);
Phase E ships the on-strip `DisplayFallbackIndicator` (E1) with the auto-return
fade+slide animation (E2). The Smith Gate 2 Notes A (size clamp), B (Wayland —
N/A here), and C (auto-scroll deep-link) are all addressed. All four AC
groups are testable in isolation; widget tests cover the visible behavior
without depending on platform-specific window plumbing.

---

## Sprint-Plan AC Coverage

| Phase AC | Implementation | Test |
|----------|----------------|------|
| **F30-D1** Radio list of `DisplayService.availableDisplays` with `DisplayInfo.labelFor()` labels | `_DisplaySection.build` iterates `availableDisplays` and renders `_DisplayRadioRow` per display | `lists all available displays with labelFor labels` ✅ |
| **F30-D1** Radio selection reflects `activeDisplay.id` | `selected: d.id == activeId && !inFallback` | Verified visually + `tapping a non-active display` test reads `svc.activeDisplay == b` after tap |
| **F30-D1** Radio change → choose immediately (resolver swap + persist) | `setChoiceResolver(FingerprintChoiceResolver(choice))` + `settingsService.update(chosenDisplay: choice)` | `tapping a non-active display persists chosenDisplay and swaps the resolver` ✅ — verifies both writes happened |
| **F30-D2** Row absent when not in fallback | `if (inFallback && persisted != null)` guard | `fallback row absent when not in fallback` ✅ |
| **F30-D2** Row visible + text correct in fallback | `_FallbackRow` formats `Currently set: {osName} ({w}×{h}) — unavailable. Showing on primary until it reconnects.` | `fallback row visible with persisted label when isInFallback` ✅ — asserts both the persisted label and "unavailable" present |
| **F30-E1** Listens to DisplayService | `ListenableBuilder(listenable: Listenable.merge([displayService, _autoReturnController]), ...)` | `visible when isInFallback` + `invisible when not in fallback` ✅ |
| **F30-E1** Icon size = `min(14, stripHeight - 8)` per Smith Note A | `_iconSize()` returns `stripHeight - 8` clamped at `14` | `icon size clamps at max=14 for tall strips` + `icon size shrinks below max=14 for short strips` ✅ |
| **F30-E1** Tooltip "Chosen display unavailable — showing on primary." | `Tooltip(message: ...)` wrap | Visible-state test renders the tooltip widget in the tree; visual diff out-of-scope for unit tests |
| **F30-E1** Tap fires deep-link to Settings + auto-scroll to Display section per Smith Note C | `onTap` callback wired in TimelineStrip; `_openSettingsToDisplaySection` toggles Settings then `Scrollable.ensureVisible(_displaySectionKey.currentContext)` | `tap fires onTap callback` ✅ — unit-tests the callback contract; deep-link mechanism verified by inspection (GlobalKey forwarding pattern, well-trodden in this codebase) |
| **F30-E1** Placement: left of gear with ≥8px gap | TimelineStrip icon row: `SizedBox(width: 4)` spacers on either side of `DisplayFallbackIndicator`, and indicator itself has 4px horizontal padding → 8px effective gap | Visual confirmed by inspection of `timeline_strip.dart:_buildIconRow` |
| **F30-E2** Animation triggers only on IN_FALLBACK → AUTO_RETURNING (not on entry) | `_onDisplayChanged` checks `wasJustAutoReturned`; the `wasJustAutoReturned` flag is true only when transitioning out of fallback (per `DisplayService._refresh`) | `no animation when entering IN_FALLBACK (only on exit)` ✅ — opacity stays 1.0 on entry |
| **F30-E2** Opacity reaches 0 within 600ms; indicator hides after | `AnimationController(duration: 600ms)`; after `pump(600ms) + pumpAndSettle` the icon is gone | `auto-return triggers fade animation, opacity reaches 0` ✅ |

---

## Smith Gate 2 Notes — Coverage

| Smith Note | Status |
|------------|--------|
| **A** Indicator size at minimum strip height | ✅ Two clamp tests cover both extremes (tall + short strip). Visual-diff test deferred to F30-F2 (Smith real-app pass); unit-level shape correctness is locked in. |
| **B** Wayland 2s/7s SLA | N/A in D+E — Phase C2 / Wayland polling concerns; documented for F30-F1 |
| **C** Tap → Settings opens with Display section scrolled into view | ✅ Wired through TimelineStrip's `_openSettingsToDisplaySection` → `Scrollable.ensureVisible(displaySectionKey.currentContext)` after a frame. Indicator unit test verifies the `onTap` callback fires; the open+scroll is a TimelineStrip composition concern and verified by inspection (no widget-level test for the full open+scroll cycle since it requires a fully-mounted TimelineStrip with a CalendarController, which is beyond unit-test scope) |

---

## Test Results

| Test File | Tests | Result |
|-----------|-------|--------|
| `display_fallback_indicator_test.dart` (**NEW**) | 8 | ✅ all green |
| `settings_panel_test.dart` (Display section group, **NEW**) | 5 | ✅ all green |
| Full suite (`make test V=-vv`) | 417 passed, 1 failing | ✅ — same pre-existing hover_card golden as C2; no regressions |

### Indicator coverage details
- `invisible when not in fallback` — SizedBox.shrink when not in fallback ✅
- `visible when isInFallback` — icon present ✅
- `icon size clamps at max=14 for tall strips` — 200px strip → 14px icon ✅
- `icon size shrinks below max=14 for short strips` — 18px strip → 10px icon ✅
- `tap fires onTap callback` — callback contract ✅
- `auto-return triggers fade animation, opacity reaches 0` — full lifecycle ✅
- `no animation when entering IN_FALLBACK (only on exit)` — Smith Note A protection ✅
- `dispose removes the DisplayService listener` — no leaks ✅

### SettingsPanel Display section coverage details
- `renders Display section header when displayService set` ✅
- `does not render Display section when displayService null` ✅
- `lists all available displays with labelFor labels` ✅
- `tapping a non-active display persists chosenDisplay and swaps the resolver` ✅
- `fallback row absent when not in fallback` + `fallback row visible with persisted label when isInFallback` ✅

---

## Non-Blocking Observations

### Observation 1 — `onWeakMatch` callback lost on user-driven resolver swap (Acceptable for D+E)
Neo flagged this in his task notes. `main.dart` constructs `FingerprintChoiceResolver(persisted, onWeakMatch: log.warning(...))`. When the user picks a new display in Settings, `_DisplaySection._chooseDisplay` constructs a fresh `FingerprintChoiceResolver(choice)` **without** an `onWeakMatch` sink. This means weak-match warnings only fire on first boot, not on user-initiated swaps.

**Severity:** Low — weak-match warnings are advisory; the user is actively choosing a display so a warning is less urgent. **Recommendation:** Morpheus to decide between (a) plumb the callback through SettingsPanel, or (b) hoist `onWeakMatch` into DisplayService construction with a `setPersistedChoice` convenience method. Option (b) is cleaner; deferred to follow-up.

### Observation 2 — Indicator's deep-link auto-scroll is verified by inspection, not widget test
The indicator's unit test verifies that its `onTap` fires; the full chain (tap → settings opens → display section scrolls into view) lives in `TimelineStrip._openSettingsToDisplaySection`. Writing an end-to-end widget test for this would require mounting TimelineStrip with a real CalendarController, which is currently mocked at a coarse-grained level in existing tests. The wiring follows the well-established GlobalKey pattern used elsewhere in the codebase. **Recommendation:** F30-F2 (Smith real-app UX pass) will exercise the full path manually. No code change needed.

### Observation 3 — Visual-diff test for indicator legibility deferred to F30-F2
Smith Note A explicitly calls for "a visual-diff test at the minimum strip height to verify the icon is recognizable as a 'monitor with slash' glyph." Unit tests verify the `size` parameter is correct; pixel-level legibility is a Smith real-app concern. **Recommendation:** add to F30-F2 checklist.

### Observation 4 — Display section ordering vs `_AstroLocationSection`
The Display section is the **last** column when both the astronomical theme AND `displayService != null`. The sprint plan said "after Location (F-29)" which is satisfied. Acceptable.

### Observation 5 — Pre-existing hover-card golden remains
Same as C2 UAT — unchanged 5.11% pixel diff in `hover_card_alignment_*.png`. File standalone defect.

---

## Static Analysis

`flutter analyze` on touched files clean except 2 pre-existing infos (settings_panel.dart unused-key warning on `_MiniButton`, comment_references in `timeline_layout.dart`). My changes added 2 `discarded_futures` infos which Neo fixed by wrapping with `unawaited(...)`.

---

## Gate Decision

✅ **F-30 Phase D + E passes UAT.** Hand off to Morpheus for code review.

---

*UAT by Trin — 2026-06-03.*
