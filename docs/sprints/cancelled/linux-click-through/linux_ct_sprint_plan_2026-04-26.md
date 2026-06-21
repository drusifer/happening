# Linux Click-Through Sprint Plan — 2026-04-26

**Owner**: @Mouse
**Status**: Approved by @Morpheus — Arch v1.1 applied (ClickThroughChannel abstraction)
**Sprint**: Linux Transparent Click-Through (CT-01 – CT-05)

---

## Sprint Goal

Enable click-through on native Wayland via a real GDK input-shape plugin. Add hover-to-focus as the primary interaction trigger. Gate transparent mode to native Wayland + gtk-layer-shell only. Provide a clear, honest explanation for XWayland/X11 users.

---

## Phase Structure

| Phase | Name | Tasks | Owner | Gate |
|---|---|---|---|---|
| A | Detection + Plugin Port | CT-A1, CT-A2, CT-A3 | Neo | Trin UAT → Morpheus review |
| B | Layer-Shell Positioning | CT-B1, CT-B2, CT-B3 | Neo | Trin UAT → Morpheus review |
| C | Integration + Polish | CT-C1, CT-C2, CT-C3 | Neo | Trin UAT → Morpheus review |

---

## Phase A — Detection + Plugin Port

**Goal**: Port the click-through plugin from the test app to the main app. Wire the Dart MethodChannel. Replace the smoke env-flag with real runtime backend detection.

### CT-A1: Port Native Plugin to Main App
- **Files**:
  - `app/linux/runner/click_through_plugin.cc` ✦ (new, ported from test app, channel = `com.happeningapp/click_through`, debug g_print removed)
  - `app/linux/runner/click_through_plugin.h` ✦ (new)
  - `app/linux/runner/my_application.cc` ✎ (register plugin)
  - `app/linux/runner/CMakeLists.txt` ✎ (add plugin source)
- **Risk**: Medium
- **Tests**: `make build-linux` passes; plugin registers without crash.

### CT-A2: Dart Channel Abstraction + Strategy Update
- **Files**:
  - `app/lib/core/linux/click_through_channel.dart` ✦ (new — `ClickThroughChannel` abstract + `NullClickThroughChannel`)
  - `app/lib/core/linux/linux_click_through_channel.dart` ✦ (new — concrete `LinuxClickThroughChannel` impl)
  - `app/lib/core/window/interaction_strategy/linux_window_interaction_strategy.dart` ✎ (takes `ClickThroughChannel`, calls `setPassThrough`, remove `MissingPluginException` catch)
  - `app/test/core/window/window_interaction_strategy_test.dart` ✎ (inject `NullClickThroughChannel` in tests)
- **Risk**: Medium
- **Tests**: existing interaction strategy tests pass with injected null channel.

### CT-A3: Runtime Detection via ClickThroughCapability
- **Files**:
  - `app/lib/core/linux/click_through_capability.dart` ✦ (new — value object + `detect(channel)` factory)
  - `app/lib/main.dart` ✎ (replace `_linuxTransparentSmokeEnabled()` with `ClickThroughCapability.detect(channel)`)
- **Risk**: Low
- **Tests**: `make test` 294+/294 green.

---

## Phase B — Layer-Shell Positioning

**Goal**: Add optional gtk-layer-shell CMake dependency. Anchor the strip via layer-shell on native Wayland. Tighten capability gate to require both native Wayland AND layer-shell.

### CT-B1: Optional Layer-Shell CMake Dep + C++ Detection
- **Files**:
  - `app/linux/CMakeLists.txt` ✎ (optional `pkg_check_modules(LAYER_SHELL IMPORTED_TARGET gtk-layer-shell-0)` + `add_definitions(-DLAYER_SHELL_AVAILABLE=1)` if found)
  - `app/linux/runner/click_through_plugin.cc` ✎ (add `isLayerShellAvailable()` method — returns compile-time bool)
- **Risk**: Medium
- **Tests**: Build passes with and without layer-shell package. `isLayerShellAvailable()` returns correct value.

### CT-B2: Layer-Shell Anchor in my_application.cc
- **Files**:
  - `app/linux/runner/my_application.cc` ✎ (`#ifdef LAYER_SHELL_AVAILABLE`: if Wayland backend, call `gtk_layer_shell_init_for_window`, anchor top/left/right, `exclusive_zone=0`)
- **Risk**: High
- **Tests**: On layer-shell system: strip anchors to top, does not drift on click-through toggle. On X11: no change.

### CT-B3: Dart Layer-Shell Gate + Capability Update
- **Files**:
  - `app/lib/core/linux/click_through_channel.dart` ✎ (add `isLayerShellAvailable()` to abstract + null impl)
  - `app/lib/core/linux/linux_click_through_channel.dart` ✎ (implement `isLayerShellAvailable()`)
  - `app/lib/core/linux/click_through_capability.dart` ✎ (update `detect()` to gate on layer-shell)
  - `app/lib/main.dart` ✎ (zero-change if Phase A already wires `capability.supported` correctly)
- **Risk**: Low
- **Tests**: `make test` green; `capability.supported` false on X11/XWayland.

---

## Phase C — Integration + Polish

**Goal**: Wire hover-to-focus (300ms primary trigger). Add CT-04 inline explanation in settings. Full smoke coverage and regression check.

### CT-C1: Hover-to-Focus Controller
- **Files**:
  - `app/lib/features/timeline/focus/hover_focus_controller.dart` ✦ (new — 300ms Timer, `onEnter`/`onExit`, calls `windowService.setFocused`)
  - `app/lib/features/timeline/timeline_strip.dart` ✎ (wrap with `MouseRegion`, wire controller)
  - `app/test/features/timeline/timeline_strip_test.dart` ✎ (hover-focus unit tests)
- **Risk**: Medium
- **Tests**: hover enter → 300ms → setFocused(true); exit → cancel + setFocused(false); hotkey path still works.

### CT-C2: CT-04 Settings Panel Inline Text
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart` ✎ (when Linux + `!linuxTransparentSupported`: show inline text below disabled transparent option)
  - `app/test/features/timeline/settings_panel_test.dart` ✎ (CT-04 text visibility test)
- **Risk**: Low
- **Tests**: Inline text appears on Linux non-Wayland; hidden on macOS/Windows/supported-Linux.

### CT-C3: Smoke Coverage + Regression Gate
- **Files**: test suite + smoke docs
- **Risk**: Medium
- **Tests**: `make format`, `make test` (all 294+ green), `make build-linux`. Record CT-01/CT-03 focus-release UAT result.

---

## Execution Rules

1. Start Phase A only after this plan is approved by @Morpheus.
2. Never start Phase B until Phase A UAT passes.
3. Never start Phase C until Phase B UAT passes.
4. CT-C3 is the final gate — all tests must pass before Morpheus close review.
5. Smith note: verify CT-03 focus-release in CT-C3 (hover-card dismiss must call `setFocused(false)`).
6. Smith note: `exclusive_zone = 0` in Phase B, not 1.
