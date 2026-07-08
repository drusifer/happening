// Concrete lunar body — enumerates moon arcs and emits fadeIn/hold/fadeOut glow.
//
// TLDR:
// Overview: For each moon-up interval intersecting the window, emits a navy->up->navy ramp spanning exactly [moonrise, moonset].
// Problem:  Lunar glow must never win over real daylight; a prior design tried to suppress this here via solar-day-anchored dusk/dawn bridging, which broke for long moon-up spans crossing solar noon.
// Solution: This body no longer knows or cares about the sun's schedule at all — arcs are a pure function of moonrise/moonset/illumination. Daytime always wins because AstronomicalBackgroundLayer composites both bodies by pointwise brightness, and solar colours are always brighter than lunar ones by palette construction.
// Breaking Changes: Replaces the prior dusk/dawn-bridging LunarBody; nightArcsFor is now moonUpArcs with a simpler signature (no AstroData).
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
      arcs.addAll(
          moonUpArcs(moonrise: ma.moonrise, moonset: ma.moonset, upColor: up));
    }
    return arcs;
  }

  /// Pure: arcs for one continuous moon-up interval, spanning exactly
  /// `[moonrise, moonset]`. Built only from moonrise/moonset/upColor — no
  /// solar-schedule input at all, so this cannot be anchored to the wrong
  /// calendar day. Whether any of it is visible against real daylight is
  /// decided downstream, by the compositing layer's brightness merge.
  /// Exposed for unit testing independent of getLunarTimes.
  static List<Arc> moonUpArcs({
    required DateTime moonrise,
    required DateTime moonset,
    required Color upColor,
  }) {
    const navy = SolarBody.nightNavy;
    final upDuration = moonset.difference(moonrise);
    if (upDuration >= _fadeDuration * 2) {
      final riseEnd = moonrise.add(_fadeDuration);
      final setStart = moonset.subtract(_fadeDuration);
      return [
        ...ramp(from: moonrise, to: riseEnd, colors: [navy, upColor]),
        ...ramp(from: riseEnd, to: setStart, colors: [upColor, upColor]),
        ...ramp(from: setStart, to: moonset, colors: [upColor, navy]),
      ];
    }
    // Too short for a full rise+hold+set shape: rise and set meet halfway.
    final mid = moonrise
        .add(Duration(microseconds: upDuration.inMicroseconds ~/ 2));
    return [
      ...ramp(from: moonrise, to: mid, colors: [navy, upColor]),
      ...ramp(from: mid, to: moonset, colors: [upColor, navy]),
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
