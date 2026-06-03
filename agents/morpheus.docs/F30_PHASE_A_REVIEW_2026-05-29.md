# Morpheus Code Review — F-30 Phase A
*Morpheus — 2026-05-29*

## Verdict: APPROVED — sprint advances to Phase B + can pipeline C/E

Implementation faithfully realizes the Phase A scope from the arch doc. Three small notes
follow, none blocking. Phase B can start, and C and E can pipeline alongside B as planned.

---

## Arch Alignment

| Arch Component | Implementation | Verdict |
|----------------|----------------|---------|
| `DisplayId` typed wrapper | `lib/core/display/display_id.dart` | ✅ Matches arch §"Core Types" |
| `DisplayInfo` value object | `lib/core/display/display_info.dart` | ✅ Fields match arch verbatim |
| `labelFor` 3-rule chain | Trimmed + generic-set + uniqueness + stable sort | ✅ Smith Note 2 fully implemented; generic set extended to `Built-in Display` (sensible add for macOS) |
| `DisplayService` ChangeNotifier | Implemented with public getters per arch §"DisplayService" | ✅ |
| State machine CHOSEN_AVAILABLE ↔ IN_FALLBACK | `_isInFallback` driven by `(nextMatch == null && hasPreference)`; `autoReturned` edge fires on the right transition | ✅ |
| 250ms debounce | `_debouncedRefresh()` drains `_refreshPending` with a while-loop | ✅ Trailing-edge coalescence per arch |
| DI surfaces (`DisplayProbe`, `DisplayEvents`, `DisplayChoiceResolver`) | Three abstract interfaces, all injected | ✅ Excellent testability |

---

## Concurrency / Lifecycle

- `_disposed` flag guards every async re-entry point (`_refresh`, `_debouncedRefresh`,
  `_onEvent`). No `notifyListeners()` can fire after dispose. Mirrors the disposed-guard
  pattern Morpheus required in `AstroDataService` (AST-E2). ✅
- `_cancelSubscription` is invoked on dispose to unhook the host event source. ✅
- Dart's single-threaded event loop means the `_refreshPending` / `_refreshInProgress`
  flags don't need atomic protection. ✅
- `initialize()` is idempotent via `_initialized` flag. ✅

---

## Code Quality

- TLDR headers present on both new files, in the project's established style. ✅
- Equality + hashCode on both `DisplayId` and `DisplayInfo` are correct and use
  `Object.hash` for the multi-field case. ✅
- No dead code; no `// ignore` directives needed; `flutter analyze` clean. ✅
- No `print` / no `debugPrint` in production code. ✅

---

## Notes (Non-Blocking)

### Note 1 — Adopt Trin's Phase B refactor for `_hasPersistedPreference()` (Action: Phase B)

Trin correctly flagged that `_hasPersistedPreference()` relies on
`_choiceResolver is! _NullChoiceResolver`. This works today because the only two
implementations are `_NullChoiceResolver` and `DisplayIdChoiceResolver`. Phase B introduces
the composite-fingerprint resolver — a fresh-install user with no persisted choice would
still get a non-null resolver, which would incorrectly set `isInFallback = true` every
session.

**Resolution for Phase B (F30-B2)**: Add `bool get hasPreference` to the
`DisplayChoiceResolver` interface. `_NullChoiceResolver` returns false; fingerprint
resolver returns false when constructed with a null/empty PersistedDisplayChoice. Replace
the runtime-type check with the interface call. Trivial.

### Note 2 — `wasJustAutoReturned` semantics deserve a doc comment (Action: Phase E)

Today's behavior: `_wasJustAutoReturned = true` → `notifyListeners()` → set back to false.
Synchronous listeners see it; later reads do not. This is the correct one-shot edge for the
Phase E indicator's fade animation, but a reader of the API today might assume the flag
stays set until acknowledged.

**Resolution**: When `DisplayFallbackIndicator` is added in F30-E2, also enrich the
`wasJustAutoReturned` doc comment to: "True only during the `notifyListeners()` cycle of
the auto-return transition. Subsequent reads return false. Consumers must capture the value
synchronously inside their listener." No code change needed in Phase A.

### Note 3 — Initial load bypasses debounce intentionally (Approval, not action)

`initialize()` calls `_refresh()` directly (not through `_debouncedRefresh`). This is
correct — the user shouldn't wait 250ms at app start for the strip to find its display.
Worth a one-line comment in Phase B/C if it gets touched.

---

## Phase A Sign-off

- All Phase A gates met
- Foundation is clean for Phase B (persistence) and Phase C (WindowService wiring)
- Phase E (FallbackIndicator) can start in parallel since `DisplayService` API is stable

---

*Reviewed: 2026-05-29 — Morpheus.*
