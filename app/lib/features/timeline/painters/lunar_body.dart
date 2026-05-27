// Concrete lunar body — enumerates moon arcs and emits night-clipped glow.
//
// TLDR:
// Overview: For each moon arc that intersects the window, emits fadeIn / hold / fadeOut arcs covering only the moon-up portion at night.
// Problem:  Lunar glow must not bleed into daytime; previous design used solar arcs and pattern branching to suppress this.
// Solution: Compute each arc's night portion as max(moonrise, sunset) → min(moonset, next sunrise) using astroData; emit no arcs if it's empty.
// Breaking Changes: Replaces the prior per-arc LunarBody with one that owns the entire window.
//
// ---------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:happening/core/astro/astro_settings.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/astro_objects.dart';
import 'package:happening/features/timeline/painters/sky_body.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';

class LunarBody extends SkyBody {
  const LunarBody({
    required this.astroData,
    required this.lat,
    required this.lng,
  });

  final AstroData astroData;
  final double lat;
  final double lng;

  static const _moonlitPeak = Color(0xFF102552);
  static const _fadeDuration = Duration(minutes: 25);

  /// Lunar glow colour scaled by [illuminationFraction] (0..1).
  static Color upColorFor(double illuminationFraction) {
    final effective = math.pow(illuminationFraction, 0.4).toDouble();
    return Color.lerp(SolarBody.nightNavy, _moonlitPeak, effective)!;
  }

  @override
  List<Arc> getArcs(DateTime windowStart, DateTime windowEnd) {
    if (astroData.illuminationFraction <= 0) return const [];
    final up = upColorFor(astroData.illuminationFraction);
    final arcs = <Arc>[];
    for (final ma in _moonArcsInWindow(windowStart, windowEnd)) {
      arcs.addAll(nightArcsFor(
        moonrise: ma.moonrise,
        moonset: ma.moonset,
        astroData: astroData,
        upColor: up,
      ));
    }
    return arcs;
  }

  /// Pure: given one moon-arc and the local [astroData], returns the lunar
  /// arcs clipped to the night portion `[civilTwilightEnd, nextCivilTwilightBegin]`
  /// intersected with `[moonrise, moonset]`. Returns `[]` if the moon is up
  /// only during daytime/twilight.
  ///
  /// Exposed for unit testing scenarios independent of getLunarTimes.
  static List<Arc> nightArcsFor({
    required DateTime moonrise,
    required DateTime moonset,
    required AstroData astroData,
    required Color upColor,
  }) {
    // Night = after dusk twilight ends, before dawn twilight begins. This
    // leaves solar's dawn/dusk amber arcs visible (lunar would otherwise
    // clip them away in the overlap region).
    final nightStart = _laterOf(
        moonrise, solarTimesNear(moonrise, astroData).civilTwilightEnd);
    final nightEnd = _earlierOf(
        moonset,
        solarTimesNear(moonset.add(const Duration(hours: 12)), astroData)
            .civilTwilightBegin);
    if (!nightEnd.isAfter(nightStart)) return const [];
    return _fadeArcs(nightStart, nightEnd, upColor);
  }

  @override
  List<AstroObject> getGlyphs(DateTime windowStart, DateTime windowEnd) {
    final glyphs = <AstroObject>[];
    for (final ma in _moonArcsInWindow(windowStart, windowEnd)) {
      glyphs.add(MoonRise(
          time: ma.moonrise, phase: ma.phase, fraction: ma.fraction));
      final transit = DateTime.fromMillisecondsSinceEpoch(
        (ma.moonrise.millisecondsSinceEpoch +
                ma.moonset.millisecondsSinceEpoch) ~/
            2,
      );
      glyphs.add(MoonTransit(time: transit, phase: ma.phase, fraction: ma.fraction));
      glyphs.add(MoonSet(time: ma.moonset, phase: ma.phase, fraction: ma.fraction));
    }
    return glyphs;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Enumerates moon arcs (rise→set pairs) overlapping [windowStart, windowEnd]
  /// by pairing each rise with the next chronological set in a ±1-day search.
  Iterable<_MoonArc> _moonArcsInWindow(DateTime ws, DateTime we) sync* {
    final searchStart = ws.subtract(const Duration(days: 1)).toLocal();
    final searchEnd = we.add(const Duration(days: 1)).toLocal();
    var date = DateTime(searchStart.year, searchStart.month, searchStart.day);
    final lastDate = DateTime(searchEnd.year, searchEnd.month, searchEnd.day);

    final rises = <_RawRise>[];
    final sets = <DateTime>[];
    while (!date.isAfter(lastDate)) {
      final lt = getLunarTimes(date, lat, lng);
      if (lt.moonrise != null) {
        rises.add(_RawRise(
            t: lt.moonrise!,
            phase: lt.phase,
            fraction: lt.illuminationFraction));
      }
      if (lt.moonset != null) sets.add(lt.moonset!);
      date = date.add(const Duration(days: 1));
    }
    rises.sort((a, b) => a.t.compareTo(b.t));
    sets.sort();

    final usedSets = <DateTime>{};
    for (final rise in rises) {
      final set = sets.firstWhere(
        (s) => s.isAfter(rise.t) && !usedSets.contains(s),
        orElse: () => DateTime.fromMillisecondsSinceEpoch(0),
      );
      if (set.millisecondsSinceEpoch == 0) continue; // no matching set
      usedSets.add(set);
      if (set.isBefore(ws) || rise.t.isAfter(we)) continue;
      yield _MoonArc(
          moonrise: rise.t,
          moonset: set,
          phase: rise.phase,
          fraction: rise.fraction);
    }
  }

  /// FadeIn → hold → fadeOut, clamped so the fades don't overrun the night.
  static List<Arc> _fadeArcs(
      DateTime nightStart, DateTime nightEnd, Color up) {
    final navy = SolarBody.nightNavy;
    final fadeMs = _fadeDuration.inMicroseconds;
    final nightMs = nightEnd.difference(nightStart).inMicroseconds;
    // Clamp each fade to at most half the night so they don't overlap.
    final eachFadeMs = math.min(fadeMs, nightMs ~/ 2);
    final fadeInEnd = nightStart.add(Duration(microseconds: eachFadeMs));
    final fadeOutStart = nightEnd.subtract(Duration(microseconds: eachFadeMs));
    return [
      Arc(
          startTime: nightStart,
          endTime: fadeInEnd,
          startColor: navy,
          endColor: up),
      if (fadeOutStart.isAfter(fadeInEnd))
        Arc(
            startTime: fadeInEnd,
            endTime: fadeOutStart,
            startColor: up,
            endColor: up),
      Arc(
          startTime: fadeOutStart,
          endTime: nightEnd,
          startColor: up,
          endColor: navy),
    ];
  }

  static DateTime _laterOf(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
  static DateTime _earlierOf(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
}

@immutable
class _MoonArc {
  const _MoonArc({
    required this.moonrise,
    required this.moonset,
    required this.phase,
    required this.fraction,
  });

  final DateTime moonrise;
  final DateTime moonset;
  final MoonPhase phase;
  final double fraction;
}

@immutable
class _RawRise {
  const _RawRise({required this.t, required this.phase, required this.fraction});

  final DateTime t;
  final MoonPhase phase;
  final double fraction;
}
