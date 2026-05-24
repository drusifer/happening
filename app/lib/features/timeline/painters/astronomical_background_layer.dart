import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/background_layer.dart'
    show BackgroundLayer;
import 'package:happening/features/timeline/painters/lunar_body.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/painters/timeline_layer.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

/// Replaces [BackgroundLayer] when the astronomical theme is active.
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

  // ---------------------------------------------------------------------------
  // Static helpers
  // ---------------------------------------------------------------------------

  /// Builds all sky bodies for the current window — today + tomorrow solar,
  /// plus one [LunarBody] per calendar date in the window.
  static ({SolarBody solar1, SolarBody solar2, List<LunarBody> lunars})
      _buildBodies(
    AstroData astroData,
    TimelineLayout layout,
    DateTime now,
    double? lat,
    double? lng,
  ) {
    final todayTimes = SolarDayTimes(
      civilTwilightBegin: astroData.civilTwilightBegin,
      sunrise: astroData.sunrise,
      solarNoon: astroData.solarNoon,
      sunset: astroData.sunset,
      civilTwilightEnd: astroData.civilTwilightEnd,
    );
    final tomorrowTimes = SolarDayTimes(
      civilTwilightBegin:
          astroData.civilTwilightBegin.add(const Duration(hours: 24)),
      sunrise: astroData.sunrise.add(const Duration(hours: 24)),
      solarNoon: astroData.solarNoon.add(const Duration(hours: 24)),
      sunset: astroData.sunset.add(const Duration(hours: 24)),
      civilTwilightEnd:
          astroData.civilTwilightEnd.add(const Duration(hours: 24)),
    );
    final solar1 = SolarBody(times: todayTimes);
    final solar2 = SolarBody(times: tomorrowTimes);

    final lunars = <LunarBody>[];
    if (lat != null && lng != null) {
      lunars.addAll(_buildLunarBodies(layout, lat, lng, solar1, solar2));
    }

    return (solar1: solar1, solar2: solar2, lunars: lunars);
  }

  /// Collects all lunar arcs visible in the layout window and pairs rises with sets.
  static List<LunarBody> _buildLunarBodies(
    TimelineLayout layout,
    double lat,
    double lng,
    SolarBody solar1,
    SolarBody solar2,
  ) {
    // Search ±1 day beyond the window so arcs straddling day boundaries
    // are always captured with both rise AND set known.
    final searchStart =
        layout.windowStart.subtract(const Duration(days: 1)).toLocal();
    final searchEnd = layout.windowEnd.add(const Duration(days: 1)).toLocal();
    var date = DateTime(searchStart.year, searchStart.month, searchStart.day);
    final lastDate = DateTime(searchEnd.year, searchEnd.month, searchEnd.day);

    final rises = <({DateTime t, MoonPhase phase, double fraction})>[];
    final sets = <DateTime>[];

    while (!date.isAfter(lastDate)) {
      final lt = getLunarTimes(date, lat, lng);
      if (lt.moonrise != null) {
        rises.add((
          t: lt.moonrise!,
          phase: lt.phase,
          fraction: lt.illuminationFraction
        ));
      }
      if (lt.moonset != null) sets.add(lt.moonset!);
      date = date.add(const Duration(days: 1));
    }

    rises.sort((a, b) => a.t.compareTo(b.t));
    sets.sort();

    final s1Ms = solar1.riseBegin!.millisecondsSinceEpoch;
    final s2Ms = solar2.riseBegin!.millisecondsSinceEpoch;

    LunarBody makeLunar(LunarDayTimes arc, int refMs) {
      final useSolar1 = (refMs - s1Ms).abs() <= (refMs - s2Ms).abs();
      return LunarBody(
        lunar: arc,
        solar: useSolar1 ? solar1 : solar2,
        prevSolar: useSolar1 ? null : solar1,
      );
    }

    final usedSets = <DateTime>{};
    final lunars = <LunarBody>[];

    // Pair each rise with the next available set (greedy, chronological).
    for (final rise in rises) {
      final moonset = sets
          .where((s) => s.isAfter(rise.t) && !usedSets.contains(s))
          .firstOrNull;
      if (moonset != null) usedSets.add(moonset);

      final arc = LunarDayTimes(
        moonrise: rise.t,
        moonset: moonset,
        phase: rise.phase,
        illuminationFraction: rise.fraction,
      );
      final arcEnd = moonset ?? rise.t.add(const Duration(hours: 14));
      if (rise.t.isAfter(layout.windowEnd) ||
          arcEnd.isBefore(layout.windowStart)) {
        continue;
      }
      lunars.add(makeLunar(arc, rise.t.millisecondsSinceEpoch));
    }

    // Orphaned sets: moon was up at window start, rose before search range.
    for (final s in sets.where((s) => !usedSets.contains(s))) {
      if (s.isBefore(layout.windowStart) || s.isAfter(layout.windowEnd)) {
        continue;
      }
      final arc = LunarDayTimes(
        moonrise: null,
        moonset: s,
        phase: rises.firstOrNull?.phase ?? MoonPhase.waningGibbous,
        illuminationFraction: rises.firstOrNull?.fraction ?? 0.8,
      );
      lunars.add(makeLunar(arc, s.millisecondsSinceEpoch));
    }

    return lunars;
  }

  /// Returns the [AstroHit] for whichever glyph [pos] is within touch range of,
  /// or null if the pointer is not over any glyph.
  AstroHit? hitTest(Offset pos, Size size) {
    const hitR = kAstroIconRadius + 6.0;
    final (:solar1, :solar2, :lunars) =
        _buildBodies(astroData, layout, now, lat, lng);
    final bodies = <SkyBody>[solar1, solar2, ...lunars];

    for (final body in bodies) {
      for (final obj in body.buildGlyphs()) {
        final gx = layout.xForTime(obj.time, now);
        if (gx < -kAstroIconRadius || gx > size.width + kAstroIconRadius) {
          continue;
        }
        final gcy = obj.cy(size.height);
        final dx = pos.dx - gx;
        final dy = pos.dy - gcy;
        if (dx * dx + dy * dy <= hitR * hitR) {
          return AstroHit(
            label: obj.label,
            time: obj.time,
            glyphX: gx,
            glyphCy: gcy,
            fraction: obj is Moon ? obj.fraction : null,
          );
        }
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Paint
  // ---------------------------------------------------------------------------

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final (:solar1, :solar2, :lunars) =
        _buildBodies(astroData, layout, now, lat, lng);
    final bodies = <SkyBody>[solar1, solar2, ...lunars];

    double combinedNightness(double x) => math.min(
          solar1.nightnessAt(x, layout, now),
          solar2.nightnessAt(x, layout, now),
        );

    // Collect and merge all gradient stops.
    final allStops = [
      for (final body in bodies) ...body.gradientStops(layout, now),
    ];
    allStops.sort((a, b) => a.x.compareTo(b.x));

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

    _paintStars(canvas, size, combinedNightness);

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

  void _paintStars(
      Canvas canvas, Size size, double Function(double x) nightness) {
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
