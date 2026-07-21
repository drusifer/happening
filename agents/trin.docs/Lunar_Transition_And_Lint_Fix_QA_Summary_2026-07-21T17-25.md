# Lunar Transition + Make Lint Fix — Final QA — 2026-07-21 17:25

## Verdict

APPROVED. The lunar dusk regression is fixed behind an independent 12-row dusk/dawn transition
matrix, and the stale Makefile analyzer scope is repaired.

## Product fix

`AstronomicalBackgroundLayer.mergeByBrightness` now selects the brighter available solar/lunar
color independently at each segment endpoint. Solar dusk can no longer carry its `nightNavy`
endpoint over an available lunar shade.

## Regression matrix

The new table-driven test enumerates 12 dusk/dawn combinations covering moon absent, already up,
rising at or around the transition, and setting at or around the transition. Each row explicitly
states its expected start, midpoint, and end colors. Before the product fix, three dusk-end rows
failed with `nightNavy`; after the fix, the focused file passes 26/26.

## Makefile fix

`ANALYZE_DIRS` always includes `lib test` and conditionally includes `integration_test` only when
`app/integration_test` exists. The shared scope is used by `analyze`, `lint-style`, and `win-test`.
The intentionally deleted, main-less integration-test stub was not restored.

## Final gates

- Focused astronomical background test: 26/26 passed.
- `make lint`: passed analyzer, metrics, and formatting; no issues and 0 formatting changes.
- `make test`: 507 passed, 5 skipped; all tests passed.
- `git diff --check`: passed.

## Changed project files

- `Makefile`
- `app/lib/features/timeline/painters/astronomical_background_layer.dart`
- `app/test/features/timeline/painters/astronomical_background_layer_test.dart`
