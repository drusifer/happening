# Sprint Plan: Pass-Through Removal + Send-to-Back
**Date**: 2026-05-13
**Status**: DRAFT — Awaiting Smith review

---

## Context

Three separate implementation attempts at transparent click-through (Linux GDK input-shape plugin, setIgnoreMouseEvents forwarding, XWayland detection) all proved fragile or platform-limited. The feature is being dropped entirely. Replacing it with a simpler, cross-platform "send to back" behavior: the user presses a button, the strip lowers behind other windows for a fixed timer period, then returns to always-on-top. Same user intent (temporarily get the strip out of the way) — zero platform-specific complexity.

---

## What is Being REMOVED

### Behavior / API
| Symbol | Location | Disposition |
|--------|----------|-------------|
| `setPassThroughEnabled(bool)` | `WindowService` | Delete |
| `supportsTransparentPassThrough()` | `WindowService` | Delete |
| `supportsTransparentPassThroughForTesting` | `WindowService` constructor | Delete |
| `setPassThrough(bool)` | `WindowInteractionStrategy` + all impls | Delete |
| `supportsTransparent` | `WindowModeAvailability` | Delete |
| `WindowMode.transparent` | `settings_service.dart` | Remove enum value → rename `overlay` |
| `usesTransparentFocusModel` | `TimelineFocusController` | Delete |
| `_enterIdleTransparentState()` | `TimelineFocusController` | Delete |
| `supportsTransparentPassThrough` ctor param | `WindowsWindowInteractionStrategy` | Delete |
| Pass-through init logic | `MacOsWindowInteractionStrategy` | Delete |
| `setIgnoreMouseEvents` comment | `main.dart` | Delete |

### Test files / stubs
| File | Change |
|------|--------|
| `window_interaction_strategy_test.dart` | Remove all pass-through tests |
| `window_service_test.dart` | Remove pass-through tests, fix constructor calls |
| `timeline_focus_controller_test.dart` | Remove transparent focus model tests |
| `timeline_strip_test.dart` | Remove click-through toggle group, fix stubs |
| `app_test.dart` | Remove `setPassThroughEnabled` stub |
| `goldens/timeline_strip_golden_test.dart` | Remove `setPassThroughEnabled` stub |

### Docs
| File | Change |
|------|--------|
| `docs/PRD.md` | Remove F-26; rewrite US-06 acceptance criteria; update Section 8 tech decisions |
| `docs/LINUX_SIMPLIFICATION.md` | Remove click-through references, update architecture description |
| `agents/cypher.docs/linux_click_through_sprint_stories_2026-04-26.md` | Archive/delete |
| `agents/cypher.docs/transparent_timestrip_*.md` | Archive/delete |

---

## What is Being ADDED / CHANGED

### Architecture: Interaction Strategy

```
WindowInteractionStrategy (abstract — factory + interface)
  BaseWindowInteractionStrategy (new — concrete shared logic)
    MacOsWindowInteractionStrategy   → alwaysOnTop overlay, no reservation
    ReservedWindowInteractionStrategy → alwaysOnTop + space reservation (Linux + Windows)
```

**Factory routing:**
- macOS → `MacOsWindowInteractionStrategy`
- Linux → `ReservedWindowInteractionStrategy`
- Windows → `ReservedWindowInteractionStrategy`

**`WindowModeAvailability`** simplifies to:
```dart
class WindowModeAvailability {
  final bool supportsReserved;  // supportsTransparent removed
}
```

**`WindowMode`** simplifies to:
```dart
enum WindowMode { overlay, reserved }
// 'transparent' removed; persisted value 'transparent' falls back to 'overlay'
```

### New Feature: Send to Back

**`BaseWindowInteractionStrategy`** gains:
```dart
Future<void> sendToBack();    // setAlwaysOnTop(false) + blur()
Future<void> restoreToFront(); // setAlwaysOnTop(true)
```

**`WindowService`** gains:
```dart
Future<void> sendToBack();
Future<void> restoreToFront();
```

**`TimelineFocusController`** repurposed:
- `_isSentToBack` replaces `_isFocused` (simpler model)
- Inactivity timer reused: 7 seconds → auto `restoreToFront()`
- No more transparent/reserved branching — same behavior on all platforms

**UI**: Existing "pass-through" button in `TimelineStrip` becomes "send to back" button, available on ALL platforms (previously gated by `supportsTransparent`).

---

## Sprint Tasks

### Phase 1 — Cleanup (remove dead code, no new behavior)

**T-01 · PRD & Doc Cleanup**
- Remove F-26 from PRD feature table
- Rewrite US-06 acceptance criteria (remove all pass-through bullet points; replace with send-to-back behavior description)
- Update Section 8 tech decisions table (remove click-through row, add send-to-back row)
- Delete stale Cypher docs: `linux_click_through_sprint_stories`, `transparent_timestrip_*`
- Update `docs/LINUX_SIMPLIFICATION.md` to reflect final arch (no plugin, ReservedWindowInteractionStrategy)
- *Owner*: Oracle + Cypher

**T-02 · Remove `WindowMode.transparent`**
- Rename enum value `transparent` → `overlay`
- Update `SettingsService.fromString` fallback: `'transparent'` → `WindowMode.overlay`
- Update all call sites: `WindowMode.transparent` → `WindowMode.overlay`
- Update settings serialisation test
- *Owner*: Neo

**T-03 · Purge `setPassThrough` from Interaction Strategy**
- Remove `setPassThrough(bool)` from `WindowInteractionStrategy` interface
- Remove `setPassThrough` from `MacOsWindowInteractionStrategy`
- Remove `setPassThrough` + `supportsTransparentPassThrough` from `WindowsWindowInteractionStrategy`
- Remove `supportsTransparent` from `WindowModeAvailability`
- Remove `supportsTransparentPassThrough` factory param from `WindowInteractionStrategy.create()`
- *Owner*: Neo

**T-04 · Refactor Interaction Strategy Hierarchy**
- Create `BaseWindowInteractionStrategy` — common `_wm`, `_mode`, `initialize()`, `setFocused()` logic
- `MacOsWindowInteractionStrategy` extends base — overrides `availability` (`supportsReserved: false`) and `initialize()` (`alwaysOnTop(true)`)
- Rename `WindowsWindowInteractionStrategy` → `ReservedWindowInteractionStrategy` — extends base — overrides `availability` (`supportsReserved: true`) and `initialize()` (Windows AppBar / Linux reserved space setup)
- Update `window_interaction_strategy.dart` factory: Linux → `ReservedWindowInteractionStrategy`
- *Owner*: Neo

**T-05 · Purge `setPassThroughEnabled` from `WindowService`**
- Remove `setPassThroughEnabled(bool)` method
- Remove `supportsTransparentPassThrough()` method
- Remove `supportsTransparentPassThroughForTesting` constructor parameter
- Remove related `_log.fine` calls
- Update `main.dart` constructor call
- *Owner*: Neo

**T-06 · Simplify `TimelineFocusController`**
- Remove `usesTransparentFocusModel` getter
- Remove `_enterIdleTransparentState()`
- Remove all `setPassThroughEnabled` calls
- Simplify `initialize()` — always enters interactive state
- Remove transparent-mode branching from `focus()`, `unfocus()`, `handleEscape()`, `handleWindowFocusLost()`, `registerUserActivity()`, `setInteractionHold()`
- *Owner*: Neo

**T-07 · Fix All Tests (post-cleanup)**
- Remove `setPassThroughEnabled` stubs from `app_test.dart`, `window_service_test.mocks.dart`, `goldens/timeline_strip_golden_test.dart`, `timeline_strip_test.dart`, `timeline_focus_controller_test.dart`
- Remove pass-through test groups from `window_interaction_strategy_test.dart`, `window_service_test.dart`
- Fix constructor call sites now that params are removed
- All tests must be GREEN before Phase 2 begins
- *Owner*: Neo + Trin

---

### Phase 2 — Send-to-Back Feature

**T-08 · Add `sendToBack` / `restoreToFront` to Strategy + Service**
- Add `sendToBack()` and `restoreToFront()` to `BaseWindowInteractionStrategy`
  - `sendToBack()`: `wm.setAlwaysOnTop(false)` + `wm.blur()`
  - `restoreToFront()`: `wm.setAlwaysOnTop(true)`
- Add `sendToBack()` / `restoreToFront()` pass-through methods to `WindowService`
- *Owner*: Neo

**T-09 · Wire Send-to-Back in `TimelineFocusController`**
- Add `_isSentToBack` state
- `sendToBack()`: calls `_windowService.sendToBack()`, starts 7-second timer → `restoreToFront()`
- `restoreToFront()`: cancels timer, calls `_windowService.restoreToFront()`
- Timer is reset if user activates send-to-back again while already sent back
- *Owner*: Neo

**T-10 · Wire Button in `TimelineStrip`**
- Existing "pass-through" button becomes "send to back" button
- Available on ALL platforms (remove `supportsTransparent` gate)
- Button shows active state while `_isSentToBack` is true
- *Owner*: Neo

**T-11 · Tests for Send-to-Back**
- `window_service_test.dart`: `sendToBack` calls `setAlwaysOnTop(false)` + `blur()`; `restoreToFront` calls `setAlwaysOnTop(true)`
- `timeline_focus_controller_test.dart`: button triggers send-to-back; timer auto-restores after 7s; second press resets timer
- `timeline_strip_test.dart`: button available on all platforms; shows active state; auto-restores
- *Owner*: Trin

---

### Phase 3 — QA & Doc Close

**T-12 · Trin Full QA Pass**
- All tests GREEN (target: ≥ 278 — same as current baseline)
- No dead imports, no stale mocks
- Grep for `passThrough`, `click_through`, `setIgnoreMouseEvents`, `supportsTransparent`, `WindowMode.transparent` — all must be gone
- *Owner*: Trin

**T-13 · Doc Final Pass**
- `ARCH.md`: update interaction strategy section
- `USER_GUIDE.md`: remove pass-through mode description; add send-to-back behavior
- `README.md`: remove transparent pass-through from feature list
- `docs/LINUX_SIMPLIFICATION.md`: mark click-through section as removed; final arch summary
- *Owner*: Oracle

---

## Acceptance Criteria (Sprint Done)

1. Zero references to `passThrough`, `click_through`, `setIgnoreMouseEvents`, `supportsTransparent`, or `WindowMode.transparent` anywhere in `app/lib` or `app/test`
2. Interaction strategy hierarchy: `Base` → `MacOs` (macOS), `Base` → `Reserved` (Linux + Windows)
3. Send-to-back button visible and functional on ALL platforms
4. Button lowers window behind other apps; 7-second timer auto-restores always-on-top
5. All tests GREEN at or above current baseline
6. PRD F-26 removed; US-06 rewritten; no docs reference click-through as a feature

---

## Updated Feature Record

**F-26 (REMOVED)**: ~~Transparent Pass-Through Mode~~ — Dropped. Platform complexity exceeded user value.

**F-27 (NEW)**: **Send-to-Back**
> A button on the strip temporarily lowers the app window behind all other windows for 7 seconds, then automatically restores always-on-top. Available on all platforms. Lets users interact with windows that would otherwise be obscured by the strip.

**Acceptance Criteria (F-27)**:
- Button visible on all platforms in collapsed strip state
- Pressing button: window goes behind all other windows immediately
- Timer: 7 seconds after press, strip auto-returns to always-on-top
- Second press while sent-back: resets the 7-second timer
- Visual indicator: button shows active/sent-back state while timer is running
- Works identically on macOS, Linux, Windows
