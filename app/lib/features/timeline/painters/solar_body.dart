// Concrete solar cycle data wrapper and glyph builder.
//
// TLDR:
// Overview: Represents the Sun's daily cycle on the timeline.
// Problem:  Need concrete time mappings and specific colors representing sunlight and twilight blocks.
// Solution: Encapsulates SolarDayTimes, provides daylight colors, and returns Sunrise, Sun, and Sunset glyphs.
// Breaking Changes: No.
//
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';

class SolarBody extends SkyBody {
  const SolarBody({required this.times});

  final SolarDayTimes times;

  static const nightNavy = Color(0xFF05080F);
  static const dawnDusk = Color(0xFFE8722A);
  static const dayBlue = Color(0xFF3F7189);

  @override
  Color get upColor => dayBlue;
  @override
  Color get downColor => nightNavy;
  @override
  Color get twilightColor => dawnDusk;

  @override
  DateTime? get riseBegin => times.civilTwilightBegin;
  @override
  DateTime? get riseEnd => times.sunrise;
  @override
  DateTime? get peak => times.solarNoon;
  @override
  DateTime? get setBegin => times.sunset;
  @override
  DateTime? get setEnd => times.civilTwilightEnd;

  @override
  List<AstroObject> buildGlyphs() => [
        SunRise(time: times.sunrise),
        Sun(time: times.solarNoon),
        SunSet(time: times.sunset),
      ];
}
