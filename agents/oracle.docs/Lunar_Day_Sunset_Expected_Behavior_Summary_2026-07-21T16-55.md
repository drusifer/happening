# Lunar-day sunset expected behavior — evidence trace

## Answer

When the moon is already up at sunset and remains above the horizon, dusk must not terminate at
`nightNavy`/black. The intended transition is the solar dusk color into the illumination-scaled
`LunarBody.upColorFor(...)`, followed by that lunar shade while the moon remains up. The May 22
implementation expressed this as an amber-to-lunar bridge through the latter half of dusk and
explicitly made lunar `upColor` win over solar `nightNavy` at the boundary.

## Evidence

- The user-approved solar baseline anchors dusk at real `sunset` and `civilTwilightEnd`, with the
  normal solar-only path ending at night navy: `docs/sprints/F-29/astro_gradient_pre_rewrite.md:40-76`.
- The original transition harness explicitly tested "Moon up at dusk" and required an
  `amber -> up` bridge ending at civil twilight end. Historical source:
  `git show 6b09cd9^:app/test/features/timeline/painters/lunar_body_scenarios_test.dart`, lines 97-120.
- The May 22 completion record says the dusk anchor mirrors dawn and lunar `upColor` wins over
  solar `nightNavy` at boundaries: `agents/chat_archive/CHAT-ARCHIVE-20260611.md:487-488`.
- Commit `6b09cd9` replaced that harness. Current lunar scenarios now verify only the moon's own
  navy/up/navy arc and say daytime resolution belongs to the compositor:
  `app/test/features/timeline/painters/lunar_body_scenarios_test.dart:1-6,23-53`.
- Current compositor tests verify daytime, deep night, and a moon that *rises at sunset*, but do
  not assert the specified case where the moon rose earlier and is already at full `upColor` at
  sunset: `app/test/features/timeline/painters/astronomical_background_layer_test.dart:131-194`.
- The current implementation picks one body for an entire interval using only midpoint
  luminance, then uses that winner for both endpoints:
  `app/lib/features/timeline/painters/astronomical_background_layer.dart:155-194`. This permits a
  twilight segment to retain the solar arc through its `nightNavy` endpoint instead of switching
  to the still-up lunar shade at the endpoint.

## Why the harness missed the regression

It did not originally miss it. The exact regression guard was deleted/replaced in `6b09cd9`.
The replacement test checks a different geometry (moonrise exactly at sunset), and calculates
expected output from the same brightness-winner algorithm under test. It therefore validates the
new algorithm's self-consistency, not the independently specified dusk endpoint.
