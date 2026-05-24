import 'package:flutter/material.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

class SolarBody extends SkyBody {
  const SolarBody({required this.times});

  final SolarDayTimes times;

  static const nightNavy = Color(0xFF05080F);
  static const dawnDusk = Color(0xFFE8722A);
  static const dayBlue = Color(0xFF5BA3C9);

  @override Color get upColor => dayBlue;
  @override Color get downColor => nightNavy;
  @override Color get twilightColor => dawnDusk;

  @override DateTime? get riseBegin => times.civilTwilightBegin;
  @override DateTime? get riseEnd => times.sunrise;
  @override DateTime? get peak => times.solarNoon;
  @override DateTime? get setBegin => times.sunset;
  @override DateTime? get setEnd => times.civilTwilightEnd;

  @override
  void paintGlyphs(Canvas canvas, Size size, TimelineLayout layout, DateTime now) {
    final objs = <AstroObject>[
      SunRise(time: times.sunrise),
      Sun(time: times.solarNoon),
      SunSet(time: times.sunset),
    ];
    for (final obj in objs) {
      drawIfVisible(canvas, size, layout, now, obj);
    }
  }
}
