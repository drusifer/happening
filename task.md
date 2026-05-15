# Task Board — Send-to-Back Sprint
**Updated**: 2026-05-13 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal

Remove all pass-through / click-through infrastructure (three failed implementation attempts). Replace with a cross-platform "send to back" behavior: the strip drops behind other windows for 10 seconds then auto-restores. Clean baseline with no dead code.

## Source Artifacts
- Product stories: `agents/cypher.docs/smith_gate1_send_to_back_stories.md`
- UX Gate 1: `agents/smith.docs/send_to_back_gate1_review_2026-05-13.md`
- Architecture: `agents/morpheus.docs/SEND_TO_BACK_ARCH_2026-05-13.md`
- UX Gate 2: `agents/smith.docs/send_to_back_gate2_review_2026-05-13.md`
- Full sprint plan: `agents/cypher.docs/send_to_back_sprint_plan.md`

---

## Phase A — Doc Cleanup + WindowMode Rename
**Review**: [ ] pending
**Gate**: compile passes after rename; no test changes yet

### STB-A1: PRD & Doc Cleanup (T-01)
- **Goal**: Remove F-26 from PRD; rewrite US-06 AC; update Section 8 tech decisions; delete stale Cypher sprint docs; update `docs/LINUX_SIMPLIFICATION.md`.
- **Files**:
  - `docs/PRD.md` ✎
  - `docs/LINUX_SIMPLIFICATION.md` ✎
  - `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md` 🗑
  - `agents/cypher.docs/transparent_timestrip_*.md` 🗑
- **Risk**: Low (docs only)
- **Tests**: n/a

### STB-A2: Rename `WindowMode.transparent` → `WindowMode.overlay` (T-02)
- **Goal**: Rename enum value; update `fromString` fallback (`'transparent'` → `WindowMode.overlay`); update all call sites.
- **Files**:
  - `app/lib/core/settings/settings_service.dart` ✎
  - `app/test/core/settings/settings_service_test.dart` ✎
  - All callers of `WindowMode.transparent` (grep to find)
- **Risk**: Low (mechanical rename; compiler-guided)
- **Tests**: `make test` passes after rename — settings serialisation test updated

---

## Phase B — Purge Pass-Through from Strategy + Service
**Review**: [ ] pending
**Gate**: `make test` green (tests will break here; fix inline as you go)

### STB-B1: Purge `setPassThrough` + Refactor Strategy Hierarchy (T-03 + T-04)
- **Goal**: Remove `setPassThrough(bool)` and `setFocused(bool)` from interface and all impls. Create `BaseWindowInteractionStrategy` with common `_wm`/`_mode` fields. `MacOsWindowInteractionStrategy` extends base (override `availability` only). Rename `WindowsWindowInteractionStrategy` → `ReservedWindowInteractionStrategy` (rename file too). Update factory routing: Linux → `ReservedWindowInteractionStrategy`. Remove `supportsTransparent` from `WindowModeAvailability`. Remove `supportsTransparentPassThrough` factory param.
- **Files**:
  - `app/lib/core/window/interaction_strategy/window_interaction_strategy.dart` ✎
  - `app/lib/core/window/interaction_strategy/base_window_interaction_strategy.dart` ✦ NEW
  - `app/lib/core/window/interaction_strategy/macos_window_interaction_strategy.dart` ✎
  - `app/lib/core/window/interaction_strategy/windows_window_interaction_strategy.dart` → `reserved_window_interaction_strategy.dart` ✎ RENAME
  - `app/test/core/window/window_interaction_strategy_test.dart` ✎
- **Risk**: Medium (coupled interface + hierarchy change — do as one commit)
- **Tests**: Remove all pass-through tests from `window_interaction_strategy_test.dart`

### STB-B2: Purge `setPassThroughEnabled` from `WindowService` (T-05)
- **Goal**: Remove `setPassThroughEnabled(bool)`, `supportsTransparentPassThrough()`, `setInteractionFocused(bool)`, and `supportsTransparentPassThroughForTesting` ctor param. Update `main.dart`. Remove stale log lines.
- **Files**:
  - `app/lib/core/window/window_service.dart` ✎
  - `app/lib/main.dart` ✎
  - `app/test/core/window/window_service_test.dart` ✎
  - `app/test/core/window/window_service_test.mocks.dart` ✎
- **Risk**: Low (removals; compiler guides missing callers)
- **Tests**: Remove pass-through tests from `window_service_test.dart`

---

## Phase C — Simplify TimelineFocusController
**Review**: [ ] pending
**Gate**: `make test` green

### STB-C1: Redesign `TimelineFocusController` + Delete `HoverFocusController` (T-06)
- **Goal**: Remove `usesTransparentFocusModel`, `_enterIdleTransparentState()`, all `setPassThroughEnabled` calls, `_windowMode`, `_isFocused`, `_isInteractionHeld`, `isFocusedNotifier`. Simplify `initialize()` — always enters interactive state. Remove transparent branching from all methods. Delete `hover_focus_controller.dart`. Remove `_hoverFocusController` instantiation AND its import from `TimelineStrip` (stale import after file deletion = build failure).
- **Files**:
  - `app/lib/features/timeline/focus/timeline_focus_controller.dart` ✎ (full redesign)
  - `app/lib/features/timeline/focus/hover_focus_controller.dart` 🗑 DELETE
  - `app/lib/features/timeline/timeline_strip.dart` ✎ (remove _hoverFocusController, isFocusedNotifier listener, _clickThroughTimer, transparent branching)
  - `app/test/features/timeline/timeline_focus_controller_test.dart` ✎
  - `app/test/features/timeline/timeline_strip_test.dart` ✎
  - `app/test/app_test.dart` ✎
  - `app/test/goldens/timeline_strip_golden_test.dart` ✎
- **Risk**: Medium (large surface area — work file by file, compile after each)
- **Tests**: Remove click-through toggle test group; remove transparent focus model tests

---

## Phase D — Tests Green Gate
**Review**: [ ] pending (Trin owns this phase)
**Gate**: `make test` ≥ 278 GREEN — hard stop before Phase E

### STB-D1: Fix All Tests Post-Cleanup (T-07)
- **Goal**: All tests GREEN after cleanup phases. Grep for any remaining `passThrough`, `click_through`, `setIgnoreMouseEvents`, `supportsTransparent`, `WindowMode.transparent` in `app/lib` and `app/test` — all must be gone.
- **Owner**: @Trin (verify) + @Neo (fix remaining compilation errors)
- **Files**: Any remaining broken test files
- **Risk**: Low if Phase B/C were clean; medium if stray references remain
- **Tests**: `make test` must pass at or above pre-sprint baseline

---

## Phase E — Add sendToBack to Strategy + Service
**Review**: [ ] pending
**Gate**: unit tests for new methods pass

### STB-E1: `sendToBack` / `restoreToFront` in Strategy + Service (T-08)
- **Goal**: Add `sendToBack()` and `restoreToFront()` to `BaseWindowInteractionStrategy`. `sendToBack()`: `wm.setAlwaysOnTop(false)` + `wm.blur()` + `wm.lower()` (verify `lower()` availability first — see Smith Gate 2 note). `restoreToFront()`: `wm.setAlwaysOnTop(true)` only (no `focus()`). Add pass-through wrappers to `WindowService`. Add to `WindowInteractionStrategy` interface.
- **Files**:
  - `app/lib/core/window/interaction_strategy/base_window_interaction_strategy.dart` ✎
  - `app/lib/core/window/interaction_strategy/window_interaction_strategy.dart` ✎
  - `app/lib/core/window/window_service.dart` ✎
- **Risk**: Medium — verify `wm.lower()` in `window_manager` v0.5.1 Linux plugin BEFORE marking done
- **Tests**: Unit tests: `sendToBack` calls `setAlwaysOnTop(false)` + `blur()`; `restoreToFront` calls `setAlwaysOnTop(true)` only

---

## Phase F — Wire Button + Controller
**Review**: [ ] pending
**Gate**: feature works end-to-end in running app

### STB-F1: Wire `sendToBack` in `TimelineFocusController` (T-09)
- **Goal**: Add `_isSentToBack`, `isSentToBackNotifier`, `_restoreTimer`. `sendToBack()`: sets state, calls `_windowService.sendToBack()`, starts 10s timer. `restoreToFront()`: cancels timer, clears state, calls `_windowService.restoreToFront()`. Re-press resets timer.
- **Files**:
  - `app/lib/features/timeline/focus/timeline_focus_controller.dart` ✎
- **Risk**: Low
- **Tests**: Timer auto-restores after 10s; second press resets timer

### STB-F2: Wire Send-to-Back Button in `TimelineStrip` (T-10)
- **Goal**: Existing pass-through button becomes send-to-back button. Available on ALL platforms (remove capability gate). Icon: `Icons.flip_to_back`. Active state when `_focusController.isSentToBack`. Subscribe to `isSentToBackNotifier`.
- **Files**:
  - `app/lib/features/timeline/timeline_strip.dart` ✎
- **Risk**: Low
- **Tests**: Button visible on all platforms; shows active state

---

## Phase G — Send-to-Back Tests
**Review**: [ ] pending (Trin owns)
**Gate**: all new behavior covered; `make test` green

### STB-G1: Tests for Send-to-Back Feature (T-11)
- **Owner**: @Trin
- **Goal**: `window_service_test.dart` — `sendToBack` calls `setAlwaysOnTop(false)` + `blur()`; `restoreToFront` calls `setAlwaysOnTop(true)`. `timeline_focus_controller_test.dart` — button triggers send-to-back; 10s timer auto-restores; second press resets timer. `timeline_strip_test.dart` — button available all platforms; active state correct; auto-restores.
- **Files**:
  - `app/test/core/window/window_service_test.dart` ✎
  - `app/test/features/timeline/timeline_focus_controller_test.dart` ✎
  - `app/test/features/timeline/timeline_strip_test.dart` ✎
- **Risk**: Low
- **Tests**: All new AC covered

---

## Phase H — QA + Doc Close
**Review**: [ ] pending
**Gate**: sprint DONE

### STB-H1: Trin Full QA Pass (T-12)
- **Owner**: @Trin
- **Goal**: All tests GREEN ≥ 278. No dead imports. Grep confirms zero remaining `passThrough`/`click_through`/`setIgnoreMouseEvents`/`supportsTransparent`/`WindowMode.transparent` in `app/lib` and `app/test`. `make analyze` clean.
- **Risk**: Low if all prior phases clean

### STB-H2: Doc Final Pass (T-13)
- **Owner**: @Oracle
- **Goal**: Update `ARCH.md` interaction strategy section; `USER_GUIDE.md` remove pass-through, add send-to-back description; `README.md` remove transparent pass-through; `docs/LINUX_SIMPLIFICATION.md` final arch summary.
- **Files**:
  - `docs/ARCH.md` ✎
  - `docs/USER_GUIDE.md` ✎
  - `README.md` ✎
  - `docs/LINUX_SIMPLIFICATION.md` ✎
- **Risk**: Low

---

## Sprint Acceptance Criteria (Definition of Done)
1. Zero references to `passThrough`, `click_through`, `setIgnoreMouseEvents`, `supportsTransparent`, `WindowMode.transparent` in `app/lib` or `app/test`
2. Strategy hierarchy: `Base` → `MacOs` (macOS), `Base` → `Reserved` (Linux + Windows)
3. Send-to-back button visible and functional on ALL platforms
4. Button lowers window; 10s timer auto-restores always-on-top; no focus steal on restore
5. All tests GREEN at or above pre-sprint baseline
6. PRD F-26 removed; US-06 rewritten; no docs reference click-through as a feature

---

## Previous Sprint (archived below)
*Linux Click-Through Sprint — CANCELLED 2026-05-13. All CT-* tasks dropped. Feature replaced by Send-to-Back.*
