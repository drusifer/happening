# Morpheus Code Review — F-30 Phase C2 (WindowService ↔ DisplayService)
*Morpheus — 2026-06-03*

## Verdict: APPROVED — 3 forward-looking notes for D/E/F

C2 faithfully inverts the dependency per the arch doc: `WindowService` now
consumes `DisplayService.activeDisplay` and reacts to its `ChangeNotifier`
notifications. Ordering of `moveToDisplay → onDisplayChangedExtra → resize`
is correct, the existing `_displayChangeInProgress` race guard is reused
(not duplicated), and `main.dart` constructs a single `DisplayService` that
will be shared with `SettingsPanel` in F30-D1.

---

## Arch Alignment

| Arch Component | Implementation | Verdict |
|----------------|----------------|---------|
| `WindowService` consults `DisplayService.activeDisplay` instead of `_sr.getPrimaryDisplay()` (arch §"WindowService consults DisplayService") | `window_service.dart:264`, `:308` | ✅ |
| `_strategy.moveToDisplay(d)` invoked when `activeDisplay` changes (arch §"strategy.moveToDisplay(d) when activeDisplay changes") | `_onDisplayChangedInner` compares `_activeDisplay?.id ↔ nextActive.id` and invokes BEFORE `onDisplayChangedExtra` and resize | ✅ |
| Re-use existing `_displayChangeInProgress` race guard (arch §"Use existing race guard") | `_onDisplayServiceChanged → _onDisplayChanged()` routes through the same guard `didChangeMetrics` uses | ✅ |
| Linux strut auto-follows via existing C++ (arch line 17, 60–64) | LinuxWindowService.onDisplayChangedExtra calls `_reserveLinuxStrut()` after move; no new C++ | ✅ |
| Windows AppBar reseat via existing `onDisplayChangedExtra` (arch line 17, 168–177) | ordering correct; AppBar `_reserveCollapsedSpace()` re-aligned with new `screenWidth` post-move | ✅ structurally; real-display verification gated by F30-C3 |
| macOS reposition via `setBounds`/setPosition (arch line 70) | default `moveToDisplay` impl calls `wm.setPosition(workAreaOrigin)`; macOS resize then sets final size | ✅ |
| `main.dart` constructs DisplayService once + shares (arch §"Wiring") | `displayService` constructed, initialized, passed to platform-specific WindowService | ✅ (D1 will additionally pass to SettingsPanel) |

---

## SOLID / Code Smells

### Dependency Inversion ✅
`WindowService` now depends on an abstraction (`DisplayService` exposing `activeDisplay` and `ChangeNotifier`); the concrete `ScreenRetriever`-backed adapters live in `screen_retriever_adapter.dart`. Production wires the adapters in `main.dart`; tests inject stub probe + events. Clean DI.

### Single Responsibility ✅
`WindowService` still owns "physical OS window dimensions." The new listener is an additional *input* to the same responsibility, not a new responsibility.

### Open/Closed ✅
Adding a new platform requires only subclassing `WindowService` and overriding `moveToDisplay` (if the default `wm.setPosition` is insufficient). Existing platforms unchanged.

### Minor Smell — `_readActiveDisplayWidth` fallback to `_sr.getPrimaryDisplay()`
`window_service.dart:308–319` falls back to `screen_retriever` when `DisplayService.activeDisplay` is null at init. This is defensive: in main.dart we always initialize DisplayService first, so the fallback is unreachable in production. **Acceptable** — explicit safety net at a system boundary; if it becomes load-bearing in tests/edge cases the fallback can be removed once we're confident in the init ordering invariant.

### Minor Smell — `_activeDisplay` set in two places
Both `_readActiveDisplayWidth` (init path) and `_onDisplayChangedInner` (event path) assign `_activeDisplay`. Acceptable: init sets the initial value, the event path tracks subsequent changes. Could be consolidated by routing init through `_onDisplayChanged()` after the listener is attached, but that adds initialization-order complexity (the listener also triggers state-machine bookkeeping). **Leave as-is.**

### Minor Smell — `ScreenRetriever` still in WindowService constructor
`_sr` is retained for two reasons: (a) `WindowResizeStrategy.create(sr: ...)` needs it for strategy construction, (b) `_readActiveDisplayWidth` fallback path. Once D/E/F land and DisplayService is the sole source of display info, a follow-up could eliminate `_sr` from WindowService entirely and route strategy creation through DisplayService. **Defer** to post-F-30 cleanup; not blocking.

### Test Scaffolding Duplication (minor)
Four `_FakeWindowService` test helpers each define their own `_StubDisplayProbe` + `_StubDisplayEvents`. A shared `test/helpers/display_stubs.dart` would DRY this up. **Defer** — pattern is established and consistent across the suite; a follow-up DRY pass after D/E/F land is fine.

---

## Test Coverage Adequacy

| Behavior | Test |
|----------|------|
| `initialize` reads width from `DisplayService.activeDisplay` | `initialize reads width from DisplayService.activeDisplay` ✅ |
| `activeDisplay` change triggers `strategy.moveToDisplay` | `active display change calls strategy.moveToDisplay (wm.setPosition with new workAreaOrigin)` ✅ |
| `activeDisplay` change triggers resize to new width | `active display change resizes to new display width` ✅ |
| DPR-only change does NOT trigger `moveToDisplay` | `DPR-only change does not call moveToDisplay (no active change)` ✅ |
| `dispose` removes the listener | `dispose removes DisplayService listener` ✅ |
| Zero-width guard preserved post-refactor | `_onDisplayChanged: ignores transient zero-width display event` ✅ |
| Concurrent serialisation preserved | `_onDisplayChanged: concurrent calls are serialised` ✅ |
| Display-swap THEORY-D scenario still works | `THEORY-D: Linux display change re-anchors position after collapse` ✅ |

Coverage is comprehensive. The only behavior NOT directly tested:
- The `_sr.getPrimaryDisplay()` fallback path in `_readActiveDisplayWidth` — only exercised if DisplayService is uninitialized; acceptable since main.dart enforces the init ordering.
- The `onWeakMatch` logger callback in main.dart — covered indirectly via `FingerprintChoiceResolver(... onWeakMatch: ...)` tests in Phase B's `display_service_test.dart`.

---

## Forward-Looking Notes (non-blocking, for D/E/F)

### Note 1 — F30-D1 must plumb `displayService` through to `SettingsPanel`
Currently `main.dart` builds `displayService` and passes it to `WindowService` but not to `HappeningApp` / `SettingsPanel`. F30-D1 should:
- Add a `displayService:` constructor arg to `HappeningApp` and pass through to the Settings section
- On display-picker change: call `displayService.setChoiceResolver(FingerprintChoiceResolver(newChoice, onWeakMatch: <same sink>))` AND persist via `SettingsService.save(chosenDisplay: newChoice)`. Both must happen, not just one — the resolver swap drives the immediate move; the settings save drives next-boot recovery.

### Note 2 — F30-D2 / F30-E1 just listen to DisplayService
Both the fallback row in Settings and the on-strip indicator are pure readers of `DisplayService.isInFallback` / `wasJustAutoReturned`. They should subscribe via `AnimatedBuilder(animation: displayService, ...)` or a `Listenable.merge(...)`. No new service plumbing required.

### Note 3 — F30-C3 Windows hardware verification remains gated
The arch's fallback path (ABM_REMOVE + ABM_NEW cycle) is *not* implemented in C2 because the structurally-correct reseat via `_reserveCollapsedSpace()` may suffice. Drew's manual test on Windows + secondary monitor (F30-C3) is the gating check. If the AppBar fails to rebind to the new monitor's `rcTop`, switch in the fallback per arch doc §"Windows AppBar deeper dive". No design change needed for the rest of the suite.

---

## Suite Health

`make test V=-vv` → 403 passing + 1 pre-existing failing (`TimelineStrip Goldens S4-31: hover card follows mouse X`). The failure PNGs were already in the working tree at session start; this is *not* a C2 regression. Trin's UAT report flags it for a standalone visual-diff investigation. ✅

---

## Phase C2 Sign-off

- Wiring matches arch doc exactly; ordering of move → reassert → resize is correct
- Race guard reused, not duplicated
- 5 new tests + 3 refactored existing tests give confident coverage of the dependency inversion
- 3 forward-looking notes recorded for D1/D2/E1 + C3 hardware gate
- C/D/E pipelineable per Mouse's sprint plan; D and E are independently testable

**APPROVED. Loop *impl F-30-C2 COMPLETE.**

---

*Reviewed: 2026-06-03 — Morpheus.*
