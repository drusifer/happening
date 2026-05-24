import 'dart:math' as math;

import 'package:flutter/material.dart';
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

  static const _moonlitPeak = Color(0xFF102552);

  @override
  Color get upColor {
    final effective = math.pow(lunar.illuminationFraction, 0.4).toDouble();
    return Color.lerp(SolarBody.nightNavy, _moonlitPeak, effective)!;
  }

  // Night sky is always nightNavy when the moon is absent.
  @override
  Color get downColor => SolarBody.nightNavy;
  @override
  Color get twilightColor => SolarBody.nightNavy;

  // Twilight zone: same duration as solar twilight at this location.
  Duration get _twilightDuration {
    if (solar.riseBegin == null || solar.riseEnd == null) {
      return const Duration(minutes: 25);
    }
    return solar.riseEnd!.difference(solar.riseBegin!);
  }

  // Fade-in starts one twilight-duration before moonrise.
  @override
  DateTime? get riseBegin => lunar.moonrise?.subtract(_twilightDuration);
  @override
  DateTime? get riseEnd => lunar.moonrise;
  @override
  DateTime? get peak => _transit;
  @override
  DateTime? get setBegin => lunar.moonset;
  // Fade-out ends one twilight-duration after moonset.
  @override
  DateTime? get setEnd => lunar.moonset?.add(_twilightDuration);

  // Both bounds must be known — arcs are always fully paired in _buildBodies.
  DateTime? get _transit {
    final rise = lunar.moonrise;
    final set = lunar.moonset;
    if (rise == null || set == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
        (rise.millisecondsSinceEpoch + set.millisecondsSinceEpoch) ~/ 2);
  }

  /// Lunar glow: ramp in before moonrise, hold until dawn or moonset, then taper.
  ///
  /// Two patterns:
  ///   A) Moon rises at night → dark ramp → flat upColor → dawn anchor or moonset ramp.
  ///   B) Moon already up at dusk (rose in afternoon) → upColor from dusk → moonset ramp.
  ///      Detected when moonset precedes moonrise on the same calendar date.
  @override
  List<({double x, Color c})> gradientStops(
      TimelineLayout layout, DateTime now) {
    if (lunar.illuminationFraction <= 0) return const [];
    if (lunar.moonrise == null && lunar.moonset == null) return const [];

    final ctx = _GradCtx.build(
        lunar, solar, prevSolar, layout, now, _twilightDuration, upColor);

    // Pattern B: moonset precedes moonrise — moon was already up from a prev-day rise.
    final moonSetBeforeRise = lunar.moonset != null &&
        lunar.moonrise != null &&
        lunar.moonset!.isBefore(lunar.moonrise!);

    if (moonSetBeforeRise &&
        ctx.xMoonset != null &&
        !ctx.inDay(ctx.xMoonset!)) {
      return _patternBStops(ctx);
    }

    final result = <({double x, Color c})>[];

    // Pattern A: moon rises at night — ramp in, hold to dawn or moonset.
    if (ctx.xMoonrise != null && !ctx.inDay(ctx.xMoonrise!)) {
      _addPatternAStops(result, ctx);
    }

    // Post-dusk anchor: moon rose before this dusk and hasn't set yet.
    _addPostDuskStops(result, ctx);

    return result;
  }

  List<({double x, Color c})> _patternBStops(_GradCtx ctx) {
    final xMoonset = ctx.xMoonset!;
    final result = <({double x, Color c})>[];
    final xDusk = (ctx.xPrevDusk != null && ctx.xPrevDusk! < xMoonset)
        ? ctx.xPrevDusk
        : (ctx.xDuskEnd != null && ctx.xDuskEnd! < xMoonset
            ? ctx.xDuskEnd
            : null);
    if (xDusk != null) {
      result.add((x: xDusk, c: ctx.up));
    } else if (xMoonset > 0) {
      result.add((x: 1.0, c: ctx.up));
    }
    result.add((x: xMoonset, c: ctx.up));
    final xRampEnd =
        ctx.layout.xForTime(lunar.moonset!.add(ctx.duration), ctx.now);
    if (!ctx.inDay(xRampEnd)) result.add((x: xRampEnd, c: ctx.dark));
    return result;
  }

  void _addPatternAStops(List<({double x, Color c})> result, _GradCtx ctx) {
    final xMoonrise = ctx.xMoonrise!;
    final xRampStart =
        ctx.layout.xForTime(lunar.moonrise!.subtract(ctx.duration), ctx.now);
    if (!ctx.inDay(xRampStart)) {
      result.add((x: xRampStart, c: ctx.dark));
    } else if (ctx.xDuskEnd != null && xMoonrise > ctx.xDuskEnd!) {
      result.add((x: ctx.xDuskEnd!, c: ctx.dark));
    }
    result.add((x: xMoonrise, c: ctx.up));

    final xNextDawn = (ctx.xDawnBegin != null && ctx.xDawnBegin! > xMoonrise)
        ? ctx.xDawnBegin
        : null;
    if (xNextDawn != null &&
        (ctx.xMoonset == null || ctx.xMoonset! > xNextDawn)) {
      result.add((x: xNextDawn, c: ctx.up));
    } else if (ctx.xMoonset != null) {
      result.add((x: ctx.xMoonset!, c: ctx.up));
      final xRampEnd =
          ctx.layout.xForTime(lunar.moonset!.add(ctx.duration), ctx.now);
      if (!ctx.inDay(xRampEnd)) {
        result.add((x: xRampEnd, c: ctx.dark));
      } else if (xNextDawn != null) {
        result.add((x: xNextDawn, c: ctx.dark));
      }
    }
  }

  void _addPostDuskStops(List<({double x, Color c})> result, _GradCtx ctx) {
    if (ctx.xDuskEnd == null) return;
    if (ctx.xMoonrise != null && ctx.xMoonrise! >= ctx.xDuskEnd!) return;
    if (ctx.xMoonset != null && ctx.xMoonset! <= ctx.xDuskEnd!) return;
    result.add((x: ctx.xDuskEnd!, c: ctx.up));
    if (ctx.xMoonset != null) {
      result.add((x: ctx.xMoonset!, c: ctx.up));
      final xRampEnd =
          ctx.layout.xForTime(lunar.moonset!.add(ctx.duration), ctx.now);
      if (!ctx.inDay(xRampEnd)) result.add((x: xRampEnd, c: ctx.dark));
    }
  }

  @override
  List<AstroObject> buildGlyphs() {
    final transit = _transit;
    final frac = lunar.illuminationFraction;
    return [
      if (lunar.moonrise != null)
        MoonRise(time: lunar.moonrise!, phase: lunar.phase, fraction: frac),
      if (transit != null)
        MoonTransit(time: transit, phase: lunar.phase, fraction: frac),
      if (lunar.moonset != null)
        MoonSet(time: lunar.moonset!, phase: lunar.phase, fraction: frac),
    ];
  }
}

/// Pre-computed x-positions and styling bundled for gradient-stop helpers.
class _GradCtx {
  _GradCtx._({
    required this.xDawnBegin,
    required this.xDuskEnd,
    required this.xPrevDusk,
    required this.xMoonrise,
    required this.xMoonset,
    required this.duration,
    required this.up,
    required this.layout,
    required this.now,
  });

  factory _GradCtx.build(
    LunarDayTimes lunar,
    SolarBody solar,
    SolarBody? prevSolar,
    TimelineLayout layout,
    DateTime now,
    Duration duration,
    Color up,
  ) {
    return _GradCtx._(
      xDawnBegin: solar.riseBegin != null
          ? layout.xForTime(solar.riseBegin!, now)
          : null,
      xDuskEnd:
          solar.setEnd != null ? layout.xForTime(solar.setEnd!, now) : null,
      xPrevDusk: prevSolar?.setEnd != null
          ? layout.xForTime(prevSolar!.setEnd!, now)
          : null,
      xMoonrise:
          lunar.moonrise != null ? layout.xForTime(lunar.moonrise!, now) : null,
      xMoonset:
          lunar.moonset != null ? layout.xForTime(lunar.moonset!, now) : null,
      duration: duration,
      up: up,
      layout: layout,
      now: now,
    );
  }

  final double? xDawnBegin;
  final double? xDuskEnd;
  final double? xPrevDusk;
  final double? xMoonrise;
  final double? xMoonset;
  final Duration duration;
  final Color up;
  final TimelineLayout layout;
  final DateTime now;

  Color get dark => SolarBody.nightNavy;

  bool inDay(double x) =>
      xDawnBegin != null &&
      xDuskEnd != null &&
      x >= xDawnBegin! &&
      x <= xDuskEnd!;
}
