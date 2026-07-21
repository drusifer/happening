# Lunar Transition Merge Fix — 2026-07-21 17:10

## Outcome

Fixed `AstronomicalBackgroundLayer.mergeByBrightness` against Trin's independent
12-row dusk/dawn transition matrix without changing its expected colors.

## Root cause and fix

The compositor selected a single winning body from each segment's midpoint and
used that body's colors at both segment endpoints. During dusk, solar amber won
at the midpoint, so the same solar arc supplied `nightNavy` at twilight's end
even when the moon was still above the horizon.

Each segment endpoint now independently selects the brighter available solar or
lunar color through `_brighterColor`. This retains the brighter solar palette
during daylight/twilight and correctly lands on the moon's current illumination-
scaled color when solar dusk reaches navy.

## Verification

- `make format` — passed; one production file formatted.
- `make test FILE=test/features/timeline/painters/astronomical_background_layer_test.dart V=-vv`
  — 26/26 passed, including all 12 matrix rows and the existing multi-date sweep.
- Full suite intentionally left to Trin per the scoped handoff and bounded-testing rule.

## Files

- `app/lib/features/timeline/painters/astronomical_background_layer.dart`
- Trin-owned test change remains in
  `app/test/features/timeline/painters/astronomical_background_layer_test.dart`.
