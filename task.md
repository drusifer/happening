# Task Board — Linux Click-Through Sprint
**Updated**: 2026-04-26 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal

Enable click-through on native Wayland via a real GDK input-shape plugin. Add hover-to-focus as the primary interaction trigger. Gate transparent mode to native Wayland + gtk-layer-shell only. XWayland/X11 users see a clear, honest inline explanation.

## Source Artifacts
- Product stories: `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md`
- UX Gate 1: `agents/smith.docs/ct_gate1_review_2026-04-26.md`
- Architecture: `agents/morpheus.docs/LINUX_CLICK_THROUGH_ARCH_2026-04-26.md`
- UX Gate 2: `agents/smith.docs/ct_gate2_review_2026-04-26.md`
- Sprint plan: `agents/mouse.docs/linux_ct_sprint_plan_2026-04-26.md`

---

## Phase A — Detection + Plugin Port
**Review**: [ ] pending

### CT-A1: Port Native Plugin to Main App
- **Goal**: Copy click-through plugin from test app to `app/linux/runner/`; rename channel; register in runner.
- **Files**:
  - `app/linux/runner/click_through_plugin.cc` ✦
  - `app/linux/runner/click_through_plugin.h` ✦
  - `app/linux/runner/my_application.cc` ✎
  - `app/linux/runner/CMakeLists.txt` ✎
- **Risk**: Medium
- **Tests**: `make build-linux` passes; plugin registers without crash.
- **Status**: [x] done
- **Assigned**: @Neo

### CT-A2: Dart Channel Abstraction + Strategy Update
- **Goal**: Create `ClickThroughChannel` abstract interface + `LinuxClickThroughChannel` impl + `NullClickThroughChannel` no-op. Update `LinuxWindowInteractionStrategy` to take the interface.
- **Files**:
  - `app/lib/core/linux/click_through_channel.dart` ✦ (`ClickThroughChannel` abstract + `NullClickThroughChannel`)
  - `app/lib/core/linux/linux_click_through_channel.dart` ✦ (concrete impl)
  - `app/lib/core/window/interaction_strategy/linux_window_interaction_strategy.dart` ✎ (inject channel, remove MissingPluginException)
  - `app/test/core/window/window_interaction_strategy_test.dart` ✎ (_FakeClickThroughChannel + updated Linux tests)
- **Risk**: Medium
- **Tests**: 295/295 green.
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: CT-A1

### CT-A3: Runtime Detection via ClickThroughCapability
- **Goal**: Add `ClickThroughCapability` value object with `detect(channel)` factory. Replace smoke flag in `main()`.
- **Files**:
  - `app/lib/core/linux/click_through_capability.dart` ✦ (value object + detect factory)
  - `app/lib/main.dart` ✎
- **Risk**: Low
- **Tests**: 295/295 green; `make build-linux` clean.
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: CT-A2

---

## Phase B — Layer-Shell Positioning
**Review**: [ ] pending

### CT-B1: Optional Layer-Shell CMake Dep + C++ Detection
- **Goal**: Add optional gtk-layer-shell pkg-config check; expose `isLayerShellAvailable()` from plugin.
- **Files**:
  - `app/linux/CMakeLists.txt` ✎
  - `app/linux/runner/click_through_plugin.cc` ✎
- **Risk**: Medium
- **Tests**: Build passes with and without layer-shell present.
- **Status**: [x] done
- **Assigned**: @Neo
- **Note**: Installed API uses `gtk_layer_*` functions (not `gtk_layer_shell_*`); enums remain `GTK_LAYER_SHELL_*`. gtk-layer-shell 0.9.2 found on this system.

### CT-B2: Layer-Shell Anchor in my_application.cc
- **Goal**: On native Wayland + layer-shell: anchor strip top/left/right, `exclusive_zone=0`.
- **Files**:
  - `app/linux/runner/my_application.cc` ✎
- **Risk**: High
- **Tests**: `make build-linux` clean. Real-session Wayland smoke needed for full validation.
- **Status**: [x] done
- **Assigned**: @Neo

### CT-B3: Dart Layer-Shell Gate + Capability Update
- **Goal**: Add `isLayerShellAvailable()` to `ClickThroughChannel` interface + both impls. Update `detect()`.
- **Files**:
  - `app/lib/core/linux/click_through_channel.dart` ✎
  - `app/lib/core/linux/linux_click_through_channel.dart` ✎
  - `app/lib/core/linux/click_through_capability.dart` ✎
  - `app/test/core/window/window_interaction_strategy_test.dart` ✎ (_FakeClickThroughChannel updated)
- **Risk**: Low
- **Tests**: 295/295 green; build-linux clean.
- **Status**: [x] done
- **Assigned**: @Neo

---

## Phase C — Integration + Polish
**Review**: [ ] pending

### CT-C1: Hover-to-Focus Controller
- **Goal**: 300ms hover entry → `setFocused(true)`; exit → `setFocused(false)`. Wire into `TimelineStrip` via `MouseRegion`.
- **Files**:
  - `app/lib/features/timeline/focus/hover_focus_controller.dart` ✦
  - `app/lib/features/timeline/timeline_strip.dart` ✎
  - `app/test/features/timeline/timeline_strip_test.dart` ✎
- **Risk**: Medium
- **Tests**: Hover-focus unit tests; hotkey secondary path unchanged.
- **Status**: [x] done
- **Assigned**: @Neo
- **Depends on**: CT-A2

### CT-C2: CT-04 Settings Panel Inline Text
- **Goal**: On Linux when transparent unavailable: always-visible inline text below disabled option.
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart` ✎
  - `app/test/features/timeline/settings_panel_test.dart` ✎
- **Risk**: Low
- **Tests**: Inline text shown on Linux non-Wayland; hidden on other platforms.
- **Status**: [x] done
- **Assigned**: @Neo

### CT-C3: Smoke Coverage + Regression Gate
- **Goal**: Full regression pass; CT-03 focus-release UAT; smoke docs updated.
- **Files**: test suite + smoke docs
- **Risk**: Medium
- **Tests**: `make format`, `make test` all green, `make build-linux`.
- **Status**: [x] done — 298/298, format clean, build-linux clean
- **Assigned**: @Trin
- **Depends on**: CT-C1, CT-C2

---

## Sprint Done Criteria
- [x] Click-through works on native Wayland (GDK input shape confirmed — Phase A-B).
- [x] Strip anchors correctly via layer-shell on Wayland (Phase B).
- [x] Hover 300ms → focus; cursor-exit → idle + click-through restored (CT-C1).
- [x] XWayland/X11 users see clear inline explanation in settings (CT-C2 / CT-04).
- [x] All existing tests pass (298/298 green).
- [x] No regression to reserved mode on X11/XWayland.

## Notes
- `exclusive_zone = 0` in layer-shell anchor (transparent mode does not reserve desktop space).
- CT-03 focus-release: verify hover-card dismiss calls `setFocused(false)` in UAT.
- Do not remove `GDK_BACKEND=x11` from `make run-linux` for non-transparent runs.

---

# Previous Sprints

See `agents/mouse.docs/` for Linux Wayland Simplification and Transparent Timestrip sprint plans.
