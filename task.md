# Task Board — Transparent Timestrip Sprint
**Updated**: 2026-04-24 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal
Make Happening visible without trapping the user behind the strip. macOS uses transparent click-through idle mode; Windows/Linux expose only reliable window modes. Focused mode makes Happening opaque and interactive.

## Source Artifacts
- Product stories: `agents/cypher.docs/transparent_timestrip_sprint_stories_2026-04-24T15:04.md`
- UX Gate 1: `agents/smith.docs/transparent_timestrip_gate1_review_2026-04-24T15:06.md`
- Architecture: `agents/morpheus.docs/TRANSPARENT_TIMESTRIP_ARCH_2026-04-24T15:08.md`
- UX Gate 2: `agents/smith.docs/transparent_timestrip_gate2_review_2026-04-24T15:09.md`

---

## Phase A — Capability Spike

### TT-A1: Verify Platform Click-Through
- **Goal**: Prove `setIgnoreMouseEvents(forward: true)` behavior for supported platforms.
- **Files**:
  - `app/lib/core/window/window_service.dart` ✎
  - `app/test/core/window/window_service_test.dart` ✎
- **Risk**: High
- **Tests**: mock coverage for pass-through toggling; manual macOS/Windows notes required
- **Status**: [x] done
- **Assigned**: @Neo
- **Phase A Result**: `WindowService.setPassThroughEnabled()` now wraps `setIgnoreMouseEvents(enabled, forward: true)` behind platform availability, with unit coverage for enable, disable, and unsupported no-op behavior.

### TT-A2: Decide Hotkey Mechanism
- **Goal**: Choose package or native bridge for global focus hotkey.
- **Files**:
  - `app/pubspec.yaml` ✎ if dependency needed
  - `agents/morpheus.docs/TRANSPARENT_TIMESTRIP_ARCH_2026-04-24T15:08.md` ✎ if decision changes
- **Risk**: Medium
- **Tests**: feasibility note plus implementation target
- **Status**: [x] done
- **Assigned**: @Morpheus/@Neo
- **Phase A Result**: Use `hotkey_manager` as the Phase D implementation target. It is purpose-built for desktop global hotkeys and supports macOS, Windows, and Linux; defer adding the dependency until TT-D2.

### TT-A3: Linux Availability Decision
- **Goal**: Decide whether Linux transparent mode is exposed or hidden this sprint.
- **Files**:
  - `agents/morpheus.docs/TRANSPARENT_TIMESTRIP_ARCH_2026-04-24T15:08.md` ✎ if decision changes
- **Risk**: Medium
- **Tests**: real-session or documented fallback; default to hidden if unproven
- **Status**: [x] done
- **Assigned**: @Trin/@Morpheus
- **Phase A Result**: Linux transparent mode remains hidden this sprint. Prior real-session evidence showed a `setIgnoreMouseEvents` transparent/static-window attempt produced an unusable black bar, and no new real-session proof supersedes that.

---

## Phase B — Settings Foundation

### TT-B1: Add Window Mode Settings
- **Goal**: Add `WindowMode` and `idleTimelineOpacity` to persisted settings.
- **Files**:
  - `app/lib/core/settings/settings_service.dart` ✎
  - `app/test/core/settings/settings_service_test.dart` ✎
- **Risk**: Medium
- **Tests**: default values, JSON migration, clamp invalid opacity, preserve existing settings
- **Status**: [x] done
- **Assigned**: @Neo
- **Phase B Result**: `AppSettings` now persists `windowMode` and `idleTimelineOpacity`, clamps persisted opacity into the approved range, and exposes `effectiveWindowMode()` for platform-safe startup behavior.

### TT-B2: Load Effective Mode Before Window Init
- **Goal**: Ensure effective platform mode is available before `WindowService.initialize()`.
- **Files**:
  - `app/lib/app.dart` ✎
  - `app/lib/main.dart` ✎ if init order lives there
  - `app/lib/core/window/window_service.dart` ✎
- **Risk**: High
- **Tests**: init-order regression test; no startup height/width regression
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-B1
- **Phase B Result**: `main.dart` resolves `effectiveWindowMode(defaultTargetPlatform)` before `WindowService.initialize()`, and `WindowService` stores the initial mode without changing geometry behavior yet.

---

## Phase C — Window Interaction Strategy

### TT-C1: Add `WindowInteractionStrategy`
- **Goal**: Implement platform strategy for pass-through/focus availability separate from resize strategy.
- **Files**:
  - `app/lib/core/window/interaction_strategy/window_interaction_strategy.dart` ✦
  - `app/lib/core/window/interaction_strategy/macos_window_interaction_strategy.dart` ✦
  - `app/lib/core/window/interaction_strategy/windows_window_interaction_strategy.dart` ✦
  - `app/lib/core/window/interaction_strategy/linux_window_interaction_strategy.dart` ✦
  - `app/lib/core/window/window_service.dart` ✎
- **Risk**: High
- **Tests**: platform strategy factory tests; `setIgnoreMouseEvents` call order tests
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-A1, TT-B2
- **Phase C Result**: Added platform-specific interaction strategies and wired `WindowService` to them for pass-through and focus toggling without touching `WindowResizeStrategy`.

### TT-C2: Gate Windows AppBar Reservation By Mode
- **Goal**: Register/reassert Windows AppBar only in reserved mode.
- **Files**:
  - `app/lib/core/window/window_service.dart` ✎
  - `app/test/core/window/window_service_test.dart` ✎
- **Risk**: High
- **Tests**: transparent mode does not reserve; reserved mode preserves current AppBar behavior
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-C1
- **Phase C Result**: Windows AppBar registration/reassertion now runs only in reserved mode; transparent mode skips reservation and disposes any existing AppBar registration when switching modes.

---

## Phase D — Focus Model

### TT-D1: Add `TimelineFocusController`
- **Goal**: Own idle/focused state, Escape dismissal, and safe inactivity handling.
- **Files**:
  - `app/lib/features/timeline/focus/timeline_focus_controller.dart` ✦
  - `app/test/features/timeline/timeline_focus_controller_test.dart` ✦
- **Risk**: Medium
- **Tests**: focus, unfocus, Escape, timeout suppression while settings/details are active
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-C1
- **Phase D Result**: Added `TimelineFocusController` to own transparent idle/focused state, Escape dismissal, focus-loss dismissal, inactivity timeout, and interaction holds for settings/details.

### TT-D2: Wire Global Focus Hotkey
- **Goal**: Hotkey focuses Happening from idle pass-through mode.
- **Files**:
  - target files depend on TT-A2 decision
- **Risk**: High
- **Tests**: unit/widget test where possible; manual platform smoke required
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-A2, TT-D1
- **Phase D Result**: Added `HotkeyManagerTimelineFocusHotkeyBinding` using `hotkey_manager` and wired Ctrl/Cmd+Shift+Space to focus the strip from transparent idle mode.

### TT-D3: Make Timeline Interaction Focus-Gated
- **Goal**: Idle transparent mode passes clicks through; focused mode enables settings/refresh/quit/event details.
- **Files**:
  - `app/lib/features/timeline/timeline_strip.dart` ✎
  - `app/test/features/timeline/timeline_strip_test.dart` ✎
- **Risk**: High
- **Tests**: idle ignores event/settings interactions; focused preserves existing interactions
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-D1, TT-D2
- **Phase D Result**: `TimelineStrip` now hides interactive controls and suppresses hover expansion while transparent mode is idle; global hotkey focus restores controls and Escape returns to click-through idle.

---

## Phase E — Visual Transparency

### TT-E1: Add Idle Opacity To Painter Layers
- **Goal**: Apply idle opacity to background/ticks/events while preserving stronger now/countdown affordances.
- **Files**:
  - `app/lib/features/timeline/timeline_painter.dart` ✎
  - `app/lib/features/timeline/painters/background_layer.dart` ✎
  - `app/lib/features/timeline/painters/tick_layer.dart` ✎
  - `app/lib/features/timeline/painters/events_layer.dart` ✎
  - `app/lib/features/timeline/painters/now_indicator_layer.dart` ✎
- **Risk**: Medium
- **Tests**: painter unit/golden coverage for idle transparent and focused opaque states
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-B1, TT-D3
- **Phase E Result**: `TimelineStrip` computes idle surface/emphasis opacity from settings, and `TimelinePainter` applies opacity through background, past overlay, ticks, events, now indicator, loading, and sign-in layers.

### TT-E2: Add Focused-State Visual Feedback
- **Goal**: Focused mode is visibly distinct and reversible.
- **Files**:
  - `app/lib/features/timeline/timeline_strip.dart` ✎
  - `app/test/goldens/timeline_strip_golden_test.dart` ✎
- **Risk**: Medium
- **Tests**: golden test for focused mode
- **Status**: [ ] todo
- **Assigned**: @Neo
- **Depends on**: TT-E1

---

## Phase F — Settings UI

### TT-F1: Add Window Behavior Picker
- **Goal**: Show reliable platform modes only, with user-facing labels.
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart` ✎
  - `app/test/features/timeline/settings_panel_test.dart` ✎
- **Risk**: Medium
- **Tests**: macOS hides reserved mode; Linux hides transparent when unavailable; Windows shows available choices
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-C1
- **Phase F Result**: `SettingsPanel` shows platform-supported window behavior choices only: macOS transparent, Linux reserved, and Windows both reserved/transparent.

### TT-F2: Add Transparency Slider
- **Goal**: Add labeled idle transparency slider with live preview and clamped range.
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart` ✎
  - `app/test/features/timeline/settings_panel_test.dart` ✎
- **Risk**: Medium
- **Tests**: labels, persistence, clamp bounds, preview update
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: TT-B1, TT-E1
- **Phase F Result**: `SettingsPanel` exposes the idle transparency slider, persists updates through `SettingsService`, and keeps the expanded panel within test viewport constraints.

---

## Phase G — QA And Release Gate

### TT-G1: Full Regression
- **Goal**: Verify no regression to countdown, refresh, auth, settings, and existing timeline behavior.
- **Files**: test suite
- **Risk**: Medium
- **Tests**: `make test`
- **Status**: [ ] todo
- **Assigned**: @Trin
- **Depends on**: TT-F2

### TT-G2: Manual Platform Smoke
- **Goal**: Verify real platform behavior.
- **Checks**:
  - macOS: idle strip lets titlebar clicks through; hotkey focuses; Escape dismisses
  - Windows: transparent vs reserved modes behave as selected
  - Linux: unavailable transparent mode stays hidden unless verified
- **Risk**: High
- **Tests**: manual report
- **Status**: [ ] todo
- **Assigned**: @Trin/@Smith
- **Depends on**: TT-G1

---

## Execution Order

| Step | Phase | Gate |
|------|-------|------|
| 1 | Phase A — Capability Spike | Morpheus decision before Phase C |
| 2 | Phase B — Settings Foundation | Trin tests |
| 3 | Phase C — Window Interaction Strategy | Morpheus review |
| 4 | Phase D — Focus Model | Smith usability check |
| 5 | Phase E — Visual Transparency | Golden/widget tests |
| 6 | Phase F — Settings UI | Smith usability check |
| 7 | Phase G — QA And Release Gate | Trin + Smith |

**Rule**: Use short `*impl <phase>` loops. Do not start the next phase until tests for the current phase pass or the blocker is posted in chat.
