# Transparent Timestrip Architecture

**Date:** 2026-04-24T15:08
**Persona:** Morpheus
**Status:** Ready for Smith Gate 2 review

## Architecture Decision

Transparent timestrip requires a new interaction-mode abstraction, not another conditional inside `TimelineStrip`.

Keep `WindowResizeStrategy` responsible for geometry. Add a separate window interaction layer responsible for:
- pass-through vs interactive mouse behavior
- platform-supported window modes
- focus entry/exit
- settings-driven mode changes

This preserves the current separation between OS geometry quirks and UI interaction state.

## Existing Anchors

- `app/lib/core/window/window_service.dart`
  - owns OS window lifecycle, display metrics, expansion state, AppBar reassertion, and resize serialization.
- `app/lib/core/window/resize_strategy/*`
  - isolates platform geometry sequences.
- `app/lib/core/settings/settings_service.dart`
  - persists font/theme/time-window/calendar settings before window initialization.
- `app/lib/features/timeline/timeline_strip.dart`
  - owns timeline UI state, current settings panel, event hover interactions, and button handlers.
- `app/lib/features/timeline/timeline_painter.dart`
  - delegates to painter layers; good place to thread visual transparency without remounting the strip.

## Proposed Components

### `WindowMode`

Add a persisted enum:

```dart
enum WindowMode {
  transparent,
  reserved,
}
```

Rules:
- macOS effective mode is always `transparent`.
- Windows may use `transparent` or `reserved`.
- Linux may expose `transparent` only behind a verified support check; otherwise effective mode remains `reserved`.

### `WindowInteractionStrategy`

New strategy family parallel to `WindowResizeStrategy`:

```dart
abstract class WindowInteractionStrategy {
  WindowModeAvailability get availability;
  Future<void> initialize(WindowMode effectiveMode);
  Future<void> setPassThrough(bool enabled);
  Future<void> setFocused(bool focused);
  Future<bool> supportsTransparentMode();
}
```

Expected platform behavior:
- macOS: transparent supported; use `setIgnoreMouseEvents(true, forward: true)` in idle mode and `false` in focused mode.
- Windows: transparent likely supported by `window_manager`; still keep AppBar reserved mode path available.
- Linux: reserved mode remains default; transparent mode must be explicitly validated because previous Linux attempts produced black bars or unsupported `setIgnoreMouseEvents` behavior.

### `TimelineFocusController`

Owns focused/idle state independent of hover expansion:
- `isFocused`
- `focus()`
- `unfocus()`
- Escape dismissal
- inactivity timeout only when no settings panel or event detail is actively open

The existing hover expansion should be subordinate to focus in transparent mode:
- idle transparent mode: no event hover cards, no settings/refresh/quit click handling except any approved focus affordance
- focused mode: existing hover/detail/settings behavior works

### `TransparencyVisualState`

Derive paint values from settings and focus:
- idle opacity applies to background/ticks/events
- focused opacity uses normal theme values
- countdown, now indicator, and focus affordance use stronger opacity

Do this by threading opacity through `TimelinePainter` and layers. Avoid multiplying opacity in ad hoc widget containers.

### Settings

Extend `AppSettings`:
- `WindowMode windowMode`
- `double idleTimelineOpacity`

Settings UI:
- macOS hides reserved/statusbar mode.
- Windows shows mode picker.
- Linux shows mode picker only if transparent mode support is verified; otherwise hide transparent mode.
- Transparency slider labels: More visible / Balanced / More transparent.
- Clamp initial slider range to Smith's recommended 35%-75% for timeline/event surfaces.

## Implementation Phases

### Phase A — Platform Capability Spike
- Add tests/mocks around `setIgnoreMouseEvents`.
- Verify macOS and Windows interaction toggling paths.
- Prove Linux behavior or keep Linux transparent mode unavailable.
- Decide whether a new global hotkey dependency/native bridge is required.

#### Phase A Findings — 2026-04-24T17:12

- `WindowService` now exposes a small pass-through probe API for Phase C: `supportsTransparentPassThrough()` and `setPassThroughEnabled(bool)`.
- Supported-platform toggling calls `setIgnoreMouseEvents(enabled, forward: true)`; unsupported platforms no-op.
- Linux transparent mode remains unavailable/hidden this sprint. Existing project evidence includes a reverted Linux static transparent-window attempt that produced an unusable black bar, and there is no newer real-session proof.
- Hotkey implementation target: `hotkey_manager`, deferred to TT-D2 so Phase B/C do not take an unnecessary dependency early.

### Phase B — Settings Model
- Add `WindowMode` and `idleTimelineOpacity` to `AppSettings`.
- Preserve backward-compatible settings migration.
- Ensure settings still load before `WindowService.initialize()`.

### Phase C — Interaction Strategy
- Add `WindowInteractionStrategy` factory.
- Wire strategy into `WindowService`.
- Add `setInteractionFocused(bool)` or equivalent API.
- Ensure reserved Windows AppBar registration only runs when effective mode is reserved.

### Phase D — Focus Controller
- Add `TimelineFocusController`.
- Wire global hotkey/focus command to focused mode.
- Add Escape dismissal and safe inactivity handling.
- Keep settings/details open during active interaction.

### Phase E — Visual Transparency
- Thread idle opacity through timeline painter layers.
- Preserve stronger countdown/now/focus affordance legibility.
- Add focused vs idle visual tests/goldens.

### Phase F — Settings UI
- Add mode picker where supported.
- Hide unavailable modes.
- Add transparency slider with preview feedback.

## Risks

- Global hotkeys are not provided by current dependencies. A package or small native bridge may be needed.
- Linux transparent mode may remain unsupported. The sprint should still succeed if Linux stays reserved-only.
- `setIgnoreMouseEvents(forward: true)` must be validated on target macOS/Windows builds before claiming support.
- Existing hover expansion must not fight focus mode; hover should not be the primary focus trigger.

## Binding Constraints For Neo

- Do not merge interaction mode into `WindowResizeStrategy`.
- Do not add broad `Platform.isX` conditionals in `TimelineStrip`.
- Do not expose unavailable window modes in settings.
- Keep settings migration backward compatible.
- Preserve existing countdown, refresh, and calendar behavior.

## Gate 2 Recommendation

Morpheus recommends Smith approve this architecture. It honors the UX constraints by making focus explicit, click-through the idle default, and platform support visible only when reliable.
