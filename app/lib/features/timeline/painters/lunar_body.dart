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
  /// arcs covering the moon-up night portion. Three cases per side:
  ///
  /// * **Moon up at the dusk-finish midpoint** → lead-in is an amber→moonlit
  ///   bridge over `[duskMid, civilTwilightEnd]`, replacing solar's
  ///   amber→navy dusk-finish.
  /// * **Moon rises after duskMid** → standard navy→moonlit fadeIn at moonrise.
  /// * **Symmetric for moonset / dawn.**
  ///
  /// Returns `[]` if there is no meaningful night-and-moon-up overlap. Exposed
  /// for unit testing scenarios independent of getLunarTimes.
  static List<Arc> nightArcsFor({
    required DateTime moonrise,
    required DateTime moonset,
    required AstroData astroData,
    required Color upColor,
  }) {
    const amber = SolarBody.dawnDusk;
    const navy = SolarBody.nightNavy;

    final sDusk = solarTimesNear(moonrise, astroData);
    final sDawn =
        solarTimesNear(moonset.add(const Duration(hours: 12)), astroData);
    final duskMid = _midpoint(sDusk.sunset, sDusk.civilTwilightEnd);
    final dawnMid = _midpoint(sDawn.civilTwilightBegin, sDawn.sunrise);

    // ----- Lead-in: amber→up bridge during dusk-finish OR navy→up at moonrise.
    final DateTime fadeInStart;
    final DateTime fadeInEnd;
    final Color fadeInStartColor;
    if (!moonrise.isAfter(duskMid)) {
      fadeInStart = duskMid;
      fadeInEnd = sDusk.civilTwilightEnd;
      fadeInStartColor = amber;
    } else {
      fadeInStart = moonrise;
      fadeInEnd = moonrise.add(_fadeDuration);
      fadeInStartColor = navy;
    }

    // ----- Lead-out: up→amber bridge during dawn-rise OR up→navy at moonset.
    final DateTime fadeOutStart;
    final DateTime fadeOutEnd;
    final Color fadeOutEndColor;
    if (!moonset.isBefore(dawnMid)) {
      fadeOutStart = sDawn.civilTwilightBegin;
      fadeOutEnd = dawnMid;
      fadeOutEndColor = amber;
    } else {
      fadeOutEnd = moonset;
      fadeOutStart = moonset.subtract(_fadeDuration);
      fadeOutEndColor = navy;
    }

    if (!fadeOutStart.isAfter(fadeInEnd)) {
      // Too short for the full lead-in+hold+lead-out shape.
      // Fall back to a clamped navy→up→navy over the basic night portion.
      final nightStart = _laterOf(moonrise, sDusk.civilTwilightEnd);
      final nightEnd = _earlierOf(moonset, sDawn.civilTwilightBegin);
      if (!nightEnd.isAfter(nightStart)) return const [];
      return _shortNightFades(nightStart, nightEnd, upColor);
    }

    return [
      Arc(
          startTime: fadeInStart,
          endTime: fadeInEnd,
          startColor: fadeInStartColor,
          endColor: upColor),
      Arc(
          startTime: fadeInEnd,
          endTime: fadeOutStart,
          startColor: upColor,
          endColor: upColor),
      Arc(
          startTime: fadeOutStart,
          endTime: fadeOutEnd,
          startColor: upColor,
          endColor: fadeOutEndColor),
    ];
  }

  @override
  List<AstroObject> getGlyphs(DateTime windowStart, DateTime windowEnd) {
    final glyphs = <AstroObject>[];
    for (final ma in _moonArcsInWindow(windowStart, windowEnd)) {
      glyphs.add(
          MoonRise(time: ma.moonrise, phase: ma.phase, fraction: ma.fraction));
      final transit = DateTime.fromMillisecondsSinceEpoch(
        (ma.moonrise.millisecondsSinceEpoch +
                ma.moonset.millisecondsSinceEpoch) ~/
            2,
      );
      glyphs.add(
          MoonTransit(time: transit, phase: ma.phase, fraction: ma.fraction));
      glyphs.add(
          MoonSet(time: ma.moonset, phase: ma.phase, fraction: ma.fraction));
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

  /// Short-night fallback when the moon's night window is too brief for the
  /// standard lead-in + hold + lead-out shape: split the night in half,
  /// navy→up then up→navy.
  static List<Arc> _shortNightFades(
      DateTime nightStart, DateTime nightEnd, Color up) {
    final navy = SolarBody.nightNavy;
    final halfMs = nightEnd.difference(nightStart).inMicroseconds ~/ 2;
    final mid = nightStart.add(Duration(microseconds: halfMs));
    return [
      Arc(startTime: nightStart, endTime: mid, startColor: navy, endColor: up),
      Arc(startTime: mid, endTime: nightEnd, startColor: up, endColor: navy),
    ];
  }

  static DateTime _midpoint(DateTime a, DateTime b) =>
      DateTime.fromMillisecondsSinceEpoch(
        (a.millisecondsSinceEpoch + b.millisecondsSinceEpoch) ~/ 2,
        isUtc: a.isUtc,
      );
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
  const _RawRise(
      {required this.t, required this.phase, required this.fraction});

  final DateTime t;
  final MoonPhase phase;
  final double fraction;
}
