# Lunar Transition Matrix Test Handoff — 2026-07-21 17:09

## Test added

Added a table-driven boundary matrix to
`app/test/features/timeline/painters/astronomical_background_layer_test.dart`.
It enumerates 12 dusk/dawn combinations: moon absent, already up, rising at or around the
transition, and setting at or around the transition. Every row explicitly states the expected
start, midpoint, and end color independently of `mergeByBrightness`.

## Red result before implementation

Focused command:
`make test FILE=test/features/timeline/painters/astronomical_background_layer_test.dart V=-vv`

Result: 23 tests executed, 3 expected regression failures:

1. dusk: moon already up and remains up — expected full lunar `upColor`, got `nightNavy`
2. dusk: moon rises halfway through dusk — expected 60% navy→lunar color, got `nightNavy`
3. dusk: moon sets shortly after dusk — expected 40% lunar→navy color, got `nightNavy`

The remaining nine matrix scenarios pass. Product implementation has not yet been changed.
