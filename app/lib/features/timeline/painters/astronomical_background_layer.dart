import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Replaces [BackgroundLayer] when the astronomical theme is active.
///
/// Collects gradient stops from [SolarBody] and [LunarBody] instances, merges
/// and sorts them into a single [LinearGradient], paints stars scaled by
/// combined nightness, then draws each body's glyphs.
class AstronomicalBackgroundLayer implements TimelineLayer {
  static final _stars = _generateStars();
  static List<({double fx, double fy, double brightness})> _generateStars() {
    final rng = math.Random(42);
    return List.generate(
      90,
      (_) => (
        fx: rng.nextDouble(),
        fy: rng.nextDouble(),
        brightness: rng.nextDouble(),
      ),
    );
  }

  const AstronomicalBackgroundLayer({
    required this.astroData,
    required this.layout,
    required this.now,
    this.lat,
    this.lng,
  });

  final AstroData astroData;
  final TimelineLayout layout;
  final DateTime now;
  final double? lat;
  final double? lng;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;

    // --- Solar bodies (today + tomorrow) ---
    final todayTimes = SolarDayTimes(
      civilTwilightBegin: astroData.civilTwilightBegin,
      sunrise: astroData.sunrise,
      solarNoon: astroData.solarNoon,
      sunset: astroData.sunset,
      civilTwilightEnd: astroData.civilTwilightEnd,
    );
    final tomorrowTimes = SolarDayTimes(
      civilTwilightBegin: astroData.civilTwilightBegin.add(const Duration(hours: 24)),
      sunrise: astroData.sunrise.add(const Duration(hours: 24)),
      solarNoon: astroData.solarNoon.add(const Duration(hours: 24)),
      sunset: astroData.sunset.add(const Duration(hours: 24)),
      civilTwilightEnd: astroData.civilTwilightEnd.add(const Duration(hours: 24)),
    );
    final solar1 = SolarBody(times: todayTimes);
    final solar2 = SolarBody(times: tomorrowTimes);

    // Combined nightness: minimum across both solar cycles (most-daytime wins).
    double combinedNightness(double x) => math.min(
          solar1.nightnessAt(x, layout, now),
          solar2.nightnessAt(x, layout, now),
        );

    // --- Lunar bodies (one per visible calendar date) ---
    final lunars = <LunarBody>[];
    if (lat != null && lng != null) {
      final startLocal = layout.windowStart.toLocal();
      final endLocal = layout.windowEnd.toLocal();
      var date = DateTime(startLocal.year, startLocal.month, startLocal.day);
      final lastDate = DateTime(endLocal.year, endLocal.month, endLocal.day);
      // Assign each lunar date to the solar body whose civilTwilightBegin is
      // closest in unix-millisecond time — same logic as the sun uses its own
      // timestamps, no calendar date arithmetic needed.
      final s1Ms = todayTimes.civilTwilightBegin.millisecondsSinceEpoch;
      final s2Ms = tomorrowTimes.civilTwilightBegin.millisecondsSinceEpoch;

      while (!date.isAfter(lastDate)) {
        final lunarTimes = getLunarTimes(date, lat!, lng!);
        final dateMs = date.millisecondsSinceEpoch;
        final useSolar1 = (dateMs - s1Ms).abs() <= (dateMs - s2Ms).abs();
        final solarRef = useSolar1 ? solar1 : solar2;
        // prevSolar provides the previous night's dusk for moon-already-up detection.
        final prevSolar = useSolar1 ? null : solar1;
        lunars.add(LunarBody(lunar: lunarTimes, solar: solarRef, prevSolar: prevSolar));
        date = date.add(const Duration(days: 1));
      }
    }

    // --- Collect and merge all gradient stops ---
    final bodies = <SkyBody>[solar1, solar2, ...lunars];
    final allStops = [
      for (final body in bodies) ...body.gradientStops(layout, now),
    ];
    allStops.sort((a, b) => a.x.compareTo(b.x));

    // Deduplicate stops at the same x: keep the brighter color.
    // This lets lunar upColor anchor stops override the solar body's nightNavy
    // at civil-twilight boundaries when the moon is up, preventing dark dips.
    final deduped = <({double x, Color c})>[];
    for (final s in allStops) {
      if (deduped.isNotEmpty && (s.x - deduped.last.x).abs() < 0.5) {
        if (s.c.computeLuminance() > deduped.last.c.computeLuminance()) {
          deduped[deduped.length - 1] = s;
        }
      } else {
        deduped.add(s);
      }
    }

    // Edge colours from the solar gradient.
    final edgeLeft = _solarColorAt(0, solar1, solar2);
    final edgeRight = _solarColorAt(w, solar1, solar2);

    final colors = <Color>[edgeLeft];
    final stops = <double>[0.0];
    for (final (:x, :c) in deduped) {
      if (x > 0 && x < w) {
        colors.add(c);
        stops.add(x / w);
      }
    }
    colors.add(edgeRight);
    stops.add(1.0);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()
        ..shader = LinearGradient(colors: colors, stops: stops)
            .createShader(Rect.fromLTWH(0, 0, w, size.height)),
    );

    // --- Stars ---
    _paintStars(canvas, size, combinedNightness);

    // --- Glyphs ---
    for (final body in bodies) {
      body.paintGlyphs(canvas, size, layout, now);
    }
  }

  Color _solarColorAt(double x, SolarBody s1, SolarBody s2) {
    for (final solar in [s1, s2]) {
      final xCtb = layout.xForTime(solar.riseBegin!, now);
      final xRise = layout.xForTime(solar.riseEnd!, now);
      final xSet = layout.xForTime(solar.setBegin!, now);
      final xCte = layout.xForTime(solar.setEnd!, now);
      if (x < xCtb) return SolarBody.nightNavy;
      if (x < xRise) return SolarBody.dawnDusk;
      if (x <= xSet) return SolarBody.dayBlue;
      if (x <= xCte) return SolarBody.dawnDusk;
    }
    return SolarBody.nightNavy;
  }

  void _paintStars(Canvas canvas, Size size,
      double Function(double x) nightness) {
    final starPaint = Paint();
    for (final star in _stars) {
      final px = star.fx * size.width;
      final py = star.fy * size.height;
      final n = nightness(px);
      if (n <= 0) continue;
      final alpha = n * (0.45 + star.brightness * 0.55);
      final radius = 0.4 + star.brightness * 0.9;
      canvas.drawCircle(
        Offset(px, py),
        radius,
        starPaint..color = Colors.white.withValues(alpha: alpha),
      );
    }
  }
}
