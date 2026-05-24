import 'package:flutter_test/flutter_test.dart';
import 'package:happening/core/astro/solar_calculator.dart';
import 'package:happening/features/timeline/painters/solar_body.dart';
import 'package:happening/features/timeline/timeline_layout.dart';

void main() {
  // San Francisco — well-defined mid-latitude location.
  const lat = 37.77;
  const lng = -122.42;

  final date = DateTime(2026, 5, 18);
  final now = DateTime(2026, 5, 18, 12, 0, 0);

  group('getSolarTimes', () {
    test('returns non-null for mid-latitude location', () {
      expect(getSolarTimes(date, lat, lng), isNotNull);
    });

    test('sunrise < solarNoon < sunset', () {
      final t = getSolarTimes(date, lat, lng)!;
      expect(t.sunrise.isBefore(t.solarNoon), isTrue);
      expect(t.solarNoon.isBefore(t.sunset), isTrue);
    });

    test('civilTwilightBegin < sunrise and sunset < civilTwilightEnd', () {
      final t = getSolarTimes(date, lat, lng)!;
      expect(t.civilTwilightBegin.isBefore(t.sunrise), isTrue);
      expect(t.civilTwilightEnd.isAfter(t.sunset), isTrue);
    });

    test('events are on the expected date (within ±1 day)', () {
      final t = getSolarTimes(date, lat, lng)!;
      final lo = date.subtract(const Duration(days: 1));
      final hi = date.add(const Duration(days: 2));
      expect(t.sunrise.isAfter(lo) && t.sunrise.isBefore(hi), isTrue);
      expect(t.sunset.isAfter(lo) && t.sunset.isBefore(hi), isTrue);
    });
  });

  group('SolarBody', () {
    late TimelineLayout layout;
    late SolarBody body;
    late SolarDayTimes times;

    setUp(() {
      times = getSolarTimes(date, lat, lng)!;
      final windowStart = now.subtract(const Duration(hours: 8));
      final windowEnd = now.add(const Duration(hours: 8));
      layout = TimelineLayout(
        stripWidth: 1000.0,
        nowIndicatorX: 500.0,
        windowStart: windowStart,
        windowEnd: windowEnd,
      );
      body = SolarBody(times: times);
    });

    test('sunrise x is left of solar noon x', () {
      final xRise = layout.xForTime(times.sunrise, now);
      final xNoon = layout.xForTime(times.solarNoon, now);
      expect(xRise, lessThan(xNoon));
    });

    test('sunset x is right of solar noon x', () {
      final xNoon = layout.xForTime(times.solarNoon, now);
      final xSet = layout.xForTime(times.sunset, now);
      expect(xNoon, lessThan(xSet));
    });

    test('sunrise x is less than sunset x', () {
      final xRise = layout.xForTime(times.sunrise, now);
      final xSet = layout.xForTime(times.sunset, now);
      expect(xRise, lessThan(xSet));
    });

    test('gradientStops includes stops for all 5 solar events', () {
      final stops = body.gradientStops(layout, now);
      // riseBegin, mid(riseBegin..riseEnd), riseEnd, peak, setBegin, mid(setBegin..setEnd), setEnd = 7
      expect(stops.length, 7);
    });

    test('nightnessAt returns 0 at solar noon', () {
      final x = layout.xForTime(times.solarNoon, now);
      expect(body.nightnessAt(x, layout, now), closeTo(0.0, 0.01));
    });

    test('nightnessAt returns 1 well before civil twilight', () {
      final x = layout.xForTime(
          times.civilTwilightBegin.subtract(const Duration(hours: 2)), now);
      expect(body.nightnessAt(x, layout, now), closeTo(1.0, 0.01));
    });

    test('nightnessAt returns 1 well after civil twilight end', () {
      final x = layout.xForTime(
          times.civilTwilightEnd.add(const Duration(hours: 2)), now);
      expect(body.nightnessAt(x, layout, now), closeTo(1.0, 0.01));
    });
  });
}
