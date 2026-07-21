# Lunar-Day Sunset Regression Diagnosis — 2026-07-21 16:55

## Outcome

Confirmed regression introduced by commit `6b09cd9` (`Astro Theme fix`). When the moon was
already up before sunset, the background is expected to transition from solar dusk amber to
`LunarBody.upColorFor(illuminationFraction)`. The current compositor can instead carry the solar
arc through to `SolarBody.nightNavy` before switching to the lunar arc.

## Root cause

`AstronomicalBackgroundLayer.mergeByBrightness` builds segments only from source-arc endpoints.
For each whole segment it samples solar and lunar luminance at the midpoint, selects one winning
source, then copies that source's colors at both segment endpoints. If solar and lunar brightness
cross inside that segment, the crossover is not a breakpoint. A solar dusk segment may therefore
win at its midpoint and remain selected through its navy endpoint even though lunar glow should
win before then.

## Why the harness missed it

- The pre-refactor scenario harness explicitly tested a moon that rose in the afternoon and was
  still up at sunset, asserting an amber-to-lunar dusk bridge.
- Commit `6b09cd9` removed that assertion when `nightArcsFor` was replaced by `moonUpArcs` and the
  downstream luminance compositor.
- The replacement twilight test covers a moon that rises exactly at sunset, not a moon already at
  steady `upColor` at sunset. It also computes its expected value from the same brightness rule.
- The multi-date sweep checks only sunrise through strictly before sunset, so it never validates
  the dusk transition or nighttime landing color.

## Verification scope

Diagnosis was performed through source/history/test review. Per bounded-testing rules, no test
suite was rerun because no product code changed. No fix was implemented.

## Supporting record

Oracle confirmed the behavior contract and historical evidence in
`agents/oracle.docs/Lunar_Day_Sunset_Expected_Behavior_Summary_2026-07-21T16-55.md`.
