// Concrete solar body — tiles each day in the window with five colour arcs.
//
// TLDR:
// Overview: Emits the navy → amber → blue → amber → navy progression for every day touched by the window.
// Problem:  Need consistent solar background covering arbitrarily long windows without per-day branching at the caller.
// Solution: Iterates day offsets from AstroData.solarNoon, shifting by 24 h per step, and emits five Arcs per day plus rise/noon/set glyphs.
// Breaking Changes: Replaces the prior single-day SolarBody with one that owns the entire window.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';

class SolarBody extends SkyBody {
  const SolarBody({required this.astroData});

  final AstroData astroData;

  static const nightNavy = Color(0xFF05080F);
  static const dawnDusk = Color(0xFFE8722A);
  static const dayBlue = Color(0xFF3F7189);

  @override
  List<Arc> getArcs(DateTime windowStart, DateTime windowEnd) {
    final arcs = <Arc>[];
    for (final offset in _dayOffsetsInWindow(windowStart, windowEnd)) {
      final t = _timesAtOffset(offset);
      arcs.addAll(_arcsForDay(t));
    }
    return arcs;
  }

  @override
  List<AstroObject> getGlyphs(DateTime windowStart, DateTime windowEnd) {
    final glyphs = <AstroObject>[];
    for (final offset in _dayOffsetsInWindow(windowStart, windowEnd)) {
      final t = _timesAtOffset(offset);
      glyphs.add(SunRise(time: t.sunrise));
      glyphs.add(Sun(time: t.solarNoon));
      glyphs.add(SunSet(time: t.sunset));
    }
    return glyphs;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// All integer day offsets whose `[civilTwilightBegin, civilTwilightEnd]`
  /// range intersects the window. Range ±1 covers any plausible window.
  Iterable<int> _dayOffsetsInWindow(DateTime ws, DateTime we) sync* {
    final startHours = ws.difference(astroData.solarNoon).inMinutes / 60.0;
    final endHours = we.difference(astroData.solarNoon).inMinutes / 60.0;
    final loOffset = (startHours / 24.0).floor() - 1;
    final hiOffset = (endHours / 24.0).ceil() + 1;
    for (var i = loOffset; i <= hiOffset; i++) {
      final t = _timesAtOffset(i);
      if (!t.civilTwilightEnd.isBefore(ws) &&
          !t.civilTwilightBegin.isAfter(we)) {
        yield i;
      }
    }
  }

  ({
    DateTime civilTwilightBegin,
    DateTime sunrise,
    DateTime solarNoon,
    DateTime sunset,
    DateTime civilTwilightEnd,
  }) _timesAtOffset(int offset) {
    final shift = Duration(hours: 24 * offset);
    return (
      civilTwilightBegin: astroData.civilTwilightBegin.add(shift),
      sunrise: astroData.sunrise.add(shift),
      solarNoon: astroData.solarNoon.add(shift),
      sunset: astroData.sunset.add(shift),
      civilTwilightEnd: astroData.civilTwilightEnd.add(shift),
    );
  }

  /// Five arcs covering `[civilTwilightBegin, civilTwilightEnd]`:
  /// navy→amber (dawn-rise), amber→blue (dawn-finish), blue (day),
  /// blue→amber (dusk-start), amber→navy (dusk-finish). Built from the same
  /// shared ramp() primitive LunarBody uses for its own gradient.
  List<Arc> _arcsForDay(
          ({
            DateTime civilTwilightBegin,
            DateTime sunrise,
            DateTime solarNoon,
            DateTime sunset,
            DateTime civilTwilightEnd,
          }) t) =>
      [
        ...ramp(
          from: t.civilTwilightBegin,
          to: t.sunrise,
          colors: [nightNavy, dawnDusk, dayBlue],
        ),
        ...ramp(from: t.sunrise, to: t.sunset, colors: [dayBlue, dayBlue]),
        ...ramp(
          from: t.sunset,
          to: t.civilTwilightEnd,
          colors: [dayBlue, dawnDusk, nightNavy],
        ),
      ];
}
