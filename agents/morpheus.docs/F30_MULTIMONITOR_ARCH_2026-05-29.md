# F-30 Multi-Monitor Support — Architecture
*Morpheus — 2026-05-29*

## Verdict: PROCEED — small, well-scoped delta on existing window stack

Most of the foundation is already in place. F-30 is mainly:
1. A new `DisplayService` that owns "which display should the strip be on right now"
2. Wiring `WindowService` to consult `DisplayService` instead of calling
   `getPrimaryDisplay()` directly
3. A hot-plug state machine for fallback / auto-return
4. Settings-panel picker UI
5. An on-strip fallback indicator (per Smith Note 1)

The Linux strut C++ code (`linux_dock_window_manager_plugin.cc:42-76`) **already** scopes
struts to the monitor the window is on (via `gdk_display_get_monitor_at_window`). No C++
changes required for F-30 strut behavior. Move the window to the chosen display → strut
follows automatically. Same for Windows AppBar via the existing `onDisplayChangedExtra`
reassert path. This is a major simplification.

---

## Stories Covered

| Story | Coverage |
|-------|----------|
| US-F30-1 — Choose display | DisplayService + DisplayPreference + SettingsPanel picker |
| US-F30-2 — Per-monitor DPI | WindowService consults chosen display's `scaleFactor` from `screen_retriever` |
| US-F30-3 — Hot-plug fallback + auto-return | DisplayService state machine + screen_retriever events |
| US-F30-4 — Strut on chosen display | Already supported by existing C++ strut code; no work needed |

---

## Component Diagram

```
                                    ┌──────────────────────┐
                                    │ AppSettings          │
                                    │  + chosenDisplayId   │
                                    │   (persisted)        │
                                    └──────────┬───────────┘
                                               │
                                               ▼
┌────────────────────┐    listens    ┌──────────────────────┐
│ screen_retriever   │◄─────────────►│  DisplayService      │
│  - getAllDisplays  │   (events)    │   ChangeNotifier     │
│  - displayAdded    │               │  + activeDisplay     │
│  - displayRemoved  │               │  + isInFallback      │
│  - displayMetrics  │               │  + availableDisplays │
└────────────────────┘               └──────────┬───────────┘
                                                │ uses
                                                ▼
                  ┌─────────────────────────────────────────────┐
                  │ WindowService.initialize / displayChanged   │
                  │  - consults DisplayService.activeDisplay    │
                  │    instead of _sr.getPrimaryDisplay()       │
                  │  - calls strategy.moveToDisplay(d)          │
                  └──────────────┬──────────────────────────────┘
                                 │
                                 ▼
        ┌──────────────────────────────────────────┐
        │ WindowResizeStrategy (per platform)      │
        │  + moveToDisplay(Display d)              │
        │   Linux: setBounds(d.workArea.top)       │
        │          → strut auto-follows (C++)      │
        │   Windows: setBounds + reassertAppBar()  │
        │          → AppBar rebinds via existing   │
        │            onDisplayChangedExtra path    │
        │   macOS: setBounds                        │
        └──────────────────────────────────────────┘

        ┌──────────────────────────────────────────┐
        │ DisplayFallbackIndicator (widget)        │
        │   listens to DisplayService              │
        │   renders on the strip when isInFallback │
        │   (per Smith Gate 1 Note 1)              │
        └──────────────────────────────────────────┘

        ┌──────────────────────────────────────────┐
        │ SettingsPanel — Display section          │
        │  - lists DisplayService.availableDisplays│
        │  - writes AppSettings.chosenDisplayId    │
        │  - shows "Currently set: X — unavailable"│
        │    row if persisted choice unreachable   │
        └──────────────────────────────────────────┘
```

---

## Core Types

```dart
// New: app/lib/core/display/display_id.dart
class DisplayId {
  const DisplayId(this.value);
  final String value;  // screen_retriever's Display.id (stable per session;
                       // see "Identity & persistence" below)
}

// New: app/lib/core/display/display_info.dart
class DisplayInfo {
  final DisplayId id;
  final String? osName;          // raw screen_retriever name (may be empty/generic)
  final Size size;               // logical pixels
  final Offset workAreaOrigin;   // top-left of usable area (excludes OS taskbar)
  final Size workAreaSize;
  final double scaleFactor;      // OS DPI scale (1.0 / 1.25 / 1.5 / 2.0...)
  final bool isPrimary;

  // Derived per Smith Note 2 (garbage-name fallback):
  String labelFor(List<DisplayInfo> all) { ... }
}
```

**`labelFor` rule (Smith Note 2):**
1. If `osName` is non-null, non-empty, not in `_genericNames`
   (`{"Generic PnP Monitor", "Unknown Display", "Default Monitor", "Display"}`), AND unique
   in `all` → `osName + (isPrimary ? " — primary" : "")`
2. Else → `"Display ${index+1} — ${size.width.toInt()}×${size.height.toInt()}"
   ${isPrimary ? "— primary" : ""}`
3. Index assignment is stable: sort by `(workAreaOrigin.dx, workAreaOrigin.dy)` so the
   leftmost display is "Display 1" regardless of OS enumeration order

---

## DisplayService — the new central piece

```dart
// New: app/lib/core/display/display_service.dart
class DisplayService extends ChangeNotifier {
  DisplayService({
    required ScreenRetriever screenRetriever,
    required AppSettings settings,
  });

  // Read-only state
  DisplayInfo get activeDisplay;             // what the strip should actually use right now
  List<DisplayInfo> get availableDisplays;   // currently-connected
  bool get isInFallback;                     // chosen ≠ active because chosen is gone
  DisplayId? get persistedChoiceId;          // user's saved preference

  Future<void> initialize();                 // hydrate from settings + screen_retriever
  Future<void> chooseDisplay(DisplayId id);  // user picked a new display in Settings

  // Internal: subscribed to screen_retriever events
  void _onDisplayConnected(Display added);
  void _onDisplayDisconnected(Display removed);
  void _onDisplayMetricsChanged();
}
```

### State machine

```
                ┌────────────────────────────────┐
                │  CHOSEN_DISPLAY_AVAILABLE      │
                │  activeDisplay = chosen        │
                │  isInFallback = false          │
                └────────┬───────────────────────┘
                         │
       chosen disconnected (or app starts w/ chosen gone)
                         │
                         ▼
                ┌────────────────────────────────┐
                │  IN_FALLBACK                   │
                │  activeDisplay = primary       │
                │  isInFallback = true           │
                │  DisplayFallbackIndicator on   │
                └────────┬───────────────────────┘
                         │
              chosen reconnected
                         │
                         ▼
                ┌────────────────────────────────┐
                │  AUTO_RETURNING                │
                │  (transient ~500ms)            │
                │  - moveToDisplay(chosen)       │
                │  - emit returnedEvent          │
                │    → indicator fades out       │
                │      (Smith Note 4 cue)        │
                └────────┬───────────────────────┘
                         │
                         ▼
                back to CHOSEN_DISPLAY_AVAILABLE
```

- **Debounce**: `screen_retriever` can fire multiple events per hot-plug. Coalesce events
  with a 250ms trailing debounce in `DisplayService` to prevent thrash.
- **Race guard**: re-use the existing `_displayChangeInProgress` pattern in `WindowService`
  to serialize moves.
- **Disconnect → fallback within 2s** (AC-F30-3-1): debounce ≤ 250ms + actual move ≤ 1s
  budget = well under 2s.

---

## Identity & Persistence

`screen_retriever` exposes a `Display.id` — but its stability across reconnects is
platform-dependent. To safely persist the user's choice across sessions:

`AppSettings.chosenDisplayId` stores a **composite fingerprint**, not the raw id:

```dart
class PersistedDisplayChoice {
  final String? osName;          // for human readability + recovery
  final int widthLogical;        // size as a secondary fingerprint
  final int heightLogical;
  final double xOffsetLogical;   // position in virtual desktop
  final double yOffsetLogical;
}
```

Match algorithm on startup / hot-plug:
1. Exact match: same `osName + size + offset` → match
2. Strong match: same `osName + size` (offset changed because user moved it) → match
3. Weak match: same `osName` alone → match with warning logged
4. No match → fallback mode

This makes "I always pick my left external 1920×1080" survive across reboots even if
`screen_retriever` shuffles its internal `Display.id` values.

---

## Wiring Changes in WindowService

**Today** (`window_service.dart:98, 252`):
```dart
final display = await _sr.getPrimaryDisplay();
```

**After F-30**:
```dart
final display = _displayService.activeDisplay;
```

Additionally:
- `WindowService.initialize` adds `DisplayService` as a constructor dependency
- `WindowService` subscribes to `DisplayService` notifications and calls
  `_strategy.moveToDisplay(d)` when activeDisplay changes
- `_onDisplayChangedInner` is repurposed to be the *physical* display-change reaction;
  it consults `DisplayService.activeDisplay` for the target

### New strategy method

```dart
// app/lib/core/window/resize_strategy/window_resize_strategy.dart
abstract class WindowResizeStrategy {
  // ... existing ...
  Future<void> moveToDisplay(DisplayInfo d);
}
```

Per-platform implementations:

| Platform | `moveToDisplay` body |
|----------|----------------------|
| Linux | `setBounds(Offset(d.workAreaOrigin.dx, d.workAreaOrigin.dy), Size(d.workAreaSize.width, collapsedHeight))` — strut C++ code reassigns automatically because `gdk_display_get_monitor_at_window` queries the new monitor |
| Windows | `setBounds(...)` then `reassertAppBar()` — existing `onDisplayChangedExtra` path already handles AppBar reseat; verify it rebinds to the new monitor's `rcTop` (likely yes since AppBar is geometry-driven, not monitor-handle-driven) |
| macOS | `setBounds(...)` — top edge respects display's work area (excludes menu bar) |

### Windows AppBar deeper dive (OQ-3 commitment)

Drew committed in OQ-3 that the strut moves with selection on Windows. Two possible paths:

1. **Default-happy path**: `SHAppBarMessage(ABM_SETPOS)` accepts an `rc` rectangle in
   *virtual desktop coordinates*. Setting `rcTop` to the chosen display's `workAreaOrigin.y`
   with width spanning that display's x-range causes Windows to reserve space on the chosen
   monitor. This is what the existing `onDisplayChangedExtra` does after a metrics change
   — extend it to react to *chosen-display* changes too. **Expected to work without C++
   changes**, but must be verified by Neo with a maximize-window-on-secondary test during
   implementation.

2. **Fallback path** (if path 1 misbehaves): unregister AppBar (`ABM_REMOVE`), move
   window, re-register AppBar (`ABM_NEW` + `ABM_SETPOS`) with the new display's bounds.
   This is the existing C++ plugin's primitive set, so no new native code.

Either path is internal to `windows_window_service.dart`; story-level behavior is the same.

---

## DisplayFallbackIndicator (Smith Note 1 — MUST-FIX)

```dart
// New: app/lib/features/timeline/display_fallback_indicator.dart
class DisplayFallbackIndicator extends StatelessWidget {
  // Listens to DisplayService.isInFallback
  // When in fallback: renders a 14×14 desktop_access_disabled icon
  // immediately LEFT of the settings gear, with tooltip
  // "Chosen display unavailable — showing on primary"
  // Tap → opens Settings → Display section (deep link)
}
```

Why a glyph adjacent to the gear (vs. border accent or gear badge):
- Lowest design risk — orthogonal to existing strip painter layers
- Doesn't interact with F-29 astro layers, F-25 in-meeting countdown, or send-to-back glow
- Tap = deep link to fix; user has a clear next action
- 14×14 at 8px from gear maintains Smith's prior rule (F-29 Note 4: badge spacing near gear,
  must not reduce gear tap target). Indicator sits LEFT of gear; gear tap area unchanged.

Animation for Smith Note 4 (auto-return visibility cue):
- On fallback enter: indicator fades in over 200ms
- On auto-return: indicator fades out over 600ms with a subtle horizontal slide-out toward
  the right (toward the gear), signaling "your display came back"
- No toast / no audio — strip stays minimal

---

## Settings Panel — Display section

```
┌─ Settings ────────────────────────────────────────┐
│  ...                                              │
│  ┌─ Display ─────────────────────────────────┐    │
│  │  Show strip on:                            │    │
│  │   ○  Dell U2723QE — primary                │    │
│  │   ●  Display 2 — 1920×1080                 │    │
│  │   ○  HDMI Television                        │    │
│  │                                            │    │
│  │  Currently set: Display 3 — unavailable    │    │ (only shown when fallback active)
│  │  Showing on primary until Display 3        │    │
│  │  reconnects.                               │    │
│  └────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────┘
```

- Live switch: changing the radio fires `DisplayService.chooseDisplay(id)` immediately
- Persistence: `AppSettings.chosenDisplayId` written via existing settings.json pipeline
  (same path that F-29 added `AstroSettings`)
- The "Currently set: X — unavailable" row is a non-interactive informational row visible
  only when `isInFallback == true`

---

## Test Strategy (handoff to Trin via Mouse)

| Layer | Test |
|-------|------|
| `DisplayInfo.labelFor` | Unit: garbage names → "Display N — WxH"; unique OS names preserved; primary suffix |
| `DisplayService` state machine | Unit: chosen→fallback on disconnect; fallback→auto-return on reconnect; debounce coalesces N events |
| `DisplayService` persistence match | Unit: composite fingerprint matches across all 3 strengths |
| `WindowService.moveToDisplay` | Widget: position/size matches activeDisplay.workArea after change |
| `DisplayFallbackIndicator` | Widget: invisible when not in fallback; visible+tappable when in fallback; tap opens Settings |
| `SettingsPanel` Display section | Widget: lists displays via fake DisplayService; selection triggers chooseDisplay; "unavailable" row appears |
| **Manual UAT (Trin)** | Plug/unplug second monitor; verify fallback within 2s, auto-return on reconnect, no off-screen window, no zero-size window; maximize window on chosen display (Linux + Windows) verifies strut/AppBar |

---

## Phase Breakdown (handoff hint for Mouse)

| Phase | Scope | Rough effort |
|-------|-------|--------------|
| **F-30-A** | `DisplayInfo` + `DisplayService` (no UI yet) + tests | S |
| **F-30-B** | `AppSettings.chosenDisplayId` persistence + match algorithm + tests | S |
| **F-30-C** | `WindowResizeStrategy.moveToDisplay` per platform + WindowService wiring | M |
| **F-30-D** | `SettingsPanel` Display section UI + tests | S |
| **F-30-E** | `DisplayFallbackIndicator` widget + auto-return animation + tests (Smith Notes 1, 4) | S |
| **F-30-F** | UAT — multi-monitor manual testing (Linux, Windows, macOS) + Smith UX pass + Oracle docs | M |

Total: ~5 small + 1 medium phase. Comparable scope to F-29.

---

## Risks & Open Items for Smith Gate 2

| Risk | Mitigation |
|------|------------|
| `screen_retriever` event coverage may differ per platform (X11 vs Wayland vs Win32 vs macOS) — disconnect/reconnect detection may not fire on all platforms | **Probe during F-30-A**: Neo to add a manual `*lead consult` round if any platform misses events; document gaps in PRD. Wayland may need a polling fallback (every 5s) — graceful degradation matches F-28 Wayland no-op posture. |
| Windows AppBar may not rebind cleanly to non-primary on first try | Phase F-30-C includes manual test on secondary monitor; if it fails, use fallback path (ABM_REMOVE + ABM_NEW). No new C++ required either way. |
| Persisted display fingerprint may false-match a different physical monitor that happens to share specs (two same-model externals at different positions) | Composite includes position offset; false-match only possible if user has two identical monitors AND swaps their physical positions — acceptable edge case, log a warning. |
| Animation for auto-return may feel disconnected from strip jump | Smith to review during Gate 2; falls back to "no animation, indicator just disappears" if not validated. |

---

## Smith Note 4 Resolution (auto-return visibility cue)

**Decision**: 600ms fade-out + horizontal slide-out of the fallback indicator coincident with
the strip arriving on the returned display. No toast. The indicator's own disappearance,
combined with the visible strip-jump from primary to chosen, provides the status visibility
without adding new chrome.

Smith to validate at Gate 2.

---

*Architecture by Morpheus — 2026-05-29. Awaiting Smith Gate 2.*
