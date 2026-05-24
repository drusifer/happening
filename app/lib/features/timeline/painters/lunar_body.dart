import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

class LunarBody extends SkyBody {
  const LunarBody({required this.lunar, required this.solar, this.prevSolar});

  final LunarDayTimes lunar;
  final SolarBody solar;
  // When this body uses solar2, prevSolar is solar1 (today) — provides the
  // current night's dusk for moon-already-up cases.
  final SolarBody? prevSolar;

  static const _moonlitPeak = Color(0xFF1A3A80);

  @override
  Color get upColor {
    final effective = math.pow(lunar.illuminationFraction, 0.4).toDouble();
    return Color.lerp(SolarBody.nightNavy, _moonlitPeak, effective)!;
  }

  // Night sky is always nightNavy when the moon is absent.
  @override Color get downColor => SolarBody.nightNavy;
  @override Color get twilightColor => SolarBody.nightNavy;

  // Twilight zone: same duration as solar twilight at this location.
  Duration get _twilightDuration {
    if (solar.riseBegin == null || solar.riseEnd == null) {
      return const Duration(minutes: 25);
    }
    return solar.riseEnd!.difference(solar.riseBegin!);
  }

  // Fade-in starts one twilight-duration before moonrise.
  @override DateTime? get riseBegin => lunar.moonrise?.subtract(_twilightDuration);
  @override DateTime? get riseEnd => lunar.moonrise;
  @override DateTime? get peak => _transit;
  @override DateTime? get setBegin => lunar.moonset;
  // Fade-out ends one twilight-duration after moonset.
  @override DateTime? get setEnd => lunar.moonset?.add(_twilightDuration);

  DateTime? get _transit {
    if (lunar.moonrise == null && lunar.moonset == null) return null;
    final lo = lunar.moonrise ?? lunar.moonset!.subtract(const Duration(hours: 6));
    final hi = lunar.moonset ?? lunar.moonrise!.add(const Duration(hours: 6));
    return DateTime.fromMillisecondsSinceEpoch(
        (lo.millisecondsSinceEpoch + hi.millisecondsSinceEpoch) ~/ 2);
  }

  /// Lunar glow: ramp in before moonrise, hold until dawn or moonset, then taper.
  ///
  /// Two patterns:
  ///   A) Moon rises at night → dark ramp → flat upColor → dawn anchor or moonset ramp.
  ///   B) Moon already up at dusk (rose in afternoon) → upColor from dusk → moonset ramp.
  ///      Detected when moonset precedes moonrise on the same calendar date.
  @override
  List<({double x, Color c})> gradientStops(TimelineLayout layout, DateTime now) {
    if (lunar.illuminationFraction <= 0) return const [];
    if (lunar.moonrise == null && lunar.moonset == null) return const [];

    final duration = _twilightDuration;
    final up = upColor;
    const dark = SolarBody.nightNavy;
    final result = <({double x, Color c})>[];

    final xDawnBegin = solar.riseBegin != null
        ? layout.xForTime(solar.riseBegin!, now)
        : null;
    final xDuskEnd = solar.setEnd != null
        ? layout.xForTime(solar.setEnd!, now)
        : null;
    // prevSolar provides the PREVIOUS night's dusk when this body uses solar2.
    final xPrevDusk = prevSolar?.setEnd != null
        ? layout.xForTime(prevSolar!.setEnd!, now)
        : null;

    bool inDay(double x) =>
        xDawnBegin != null && xDuskEnd != null && x >= xDawnBegin && x <= xDuskEnd;

    final xMoonrise = lunar.moonrise != null
        ? layout.xForTime(lunar.moonrise!, now)
        : null;
    final xMoonset = lunar.moonset != null
        ? layout.xForTime(lunar.moonset!, now)
        : null;

    // Pattern B: moonset precedes moonrise on this date — the moon was already up
    // from a previous-day rise (afternoon rise), sets in the early morning, then
    // rises again in the afternoon of this date. Show the overnight moonlit period.
    final moonSetBeforeRise = lunar.moonset != null &&
        lunar.moonrise != null &&
        lunar.moonset!.isBefore(lunar.moonrise!);

    if (moonSetBeforeRise && xMoonset != null && !inDay(xMoonset)) {
      // Anchor upColor at whichever dusk boundary is visible (prev or current).
      final xDusk = (xPrevDusk != null && xPrevDusk < xMoonset)
          ? xPrevDusk
          : (xDuskEnd != null && xDuskEnd < xMoonset ? xDuskEnd : null);
      if (xDusk != null) {
        result.add((x: xDusk, c: up));
      } else if (xMoonset > 0) {
        result.add((x: 1.0, c: up)); // Moon was up at window start.
      }
      result.add((x: xMoonset, c: up));
      final xRampEnd = layout.xForTime(lunar.moonset!.add(duration), now);
      if (!inDay(xRampEnd)) result.add((x: xRampEnd, c: dark));
      // The afternoon moonrise (xMoonrise) is in daytime — solar gradient covers it.
      return result;
    }

    // Pattern A: moon rises at night — ramp in, hold to dawn or moonset.
    if (xMoonrise != null && !inDay(xMoonrise)) {
      final xRampStart = layout.xForTime(lunar.moonrise!.subtract(duration), now);
      if (!inDay(xRampStart)) {
        result.add((x: xRampStart, c: dark));
      } else if (xDuskEnd != null && xMoonrise > xDuskEnd) {
        result.add((x: xDuskEnd, c: dark));
      }
      result.add((x: xMoonrise, c: up));

      final xNextDawn =
          (xDawnBegin != null && xDawnBegin > xMoonrise) ? xDawnBegin : null;
      if (xNextDawn != null && (xMoonset == null || xMoonset > xNextDawn)) {
        result.add((x: xNextDawn, c: up));
      } else if (xMoonset != null) {
        result.add((x: xMoonset, c: up));
        final xRampEnd = layout.xForTime(lunar.moonset!.add(duration), now);
        if (!inDay(xRampEnd)) {
          result.add((x: xRampEnd, c: dark));
        } else if (xNextDawn != null) {
          result.add((x: xNextDawn, c: dark));
        }
      }
    }

    // Post-dusk anchor: moon rose before this dusk and hasn't set yet.
    // Handles e.g. moonrise at 9pm (after our dusk at 8:30pm is already past).
    if (xDuskEnd != null &&
        (xMoonrise == null || xMoonrise < xDuskEnd) &&
        (xMoonset == null || xMoonset > xDuskEnd)) {
      result.add((x: xDuskEnd, c: up));
      if (xMoonset != null) {
        result.add((x: xMoonset, c: up));
        final xRampEnd = layout.xForTime(lunar.moonset!.add(duration), now);
        if (!inDay(xRampEnd)) result.add((x: xRampEnd, c: dark));
      }
    }

    return result;
  }

  @override
  void paintGlyphs(Canvas canvas, Size size, TimelineLayout layout, DateTime now) {
    final transit = _transit;
    final objs = <AstroObject>[
      if (lunar.moonrise != null)
        MoonRise(time: lunar.moonrise!, phase: lunar.phase),
      if (transit != null)
        MoonTransit(time: transit, phase: lunar.phase),
      if (lunar.moonset != null)
        MoonSet(time: lunar.moonset!, phase: lunar.phase),
    ];
    for (final obj in objs) {
      drawIfVisible(canvas, size, layout, now, obj);
    }
  }
}
