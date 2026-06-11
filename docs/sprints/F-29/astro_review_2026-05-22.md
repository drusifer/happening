# Astro Marker Layer Review — 2026-05-22

## Verdict: Two genuine issues. Polymorphism is mostly correct.

---

## What's Correct

**TimelineLayer interface** — `SolarMarkerLayer`, `LunarMarkerLayer`, `AstronomicalBackgroundLayer` all implement the single-method interface cleanly. Callers in `TimelinePainter` treat them uniformly via the list of `TimelineLayer` instances.

**AstroObject Template Method** — `draw()` is the invariant (shadow → drawIcon). `cy()` and `drawIcon()` are the variation points. Correct textbook Template Method.

**Sun → SunRise/SunSet** — `SunRise`/`SunSet` override only `color` and `cy()`. The inherited `drawIcon()` pulls `color` via the getter, so the polymorphic override propagates without any switch or conditional. Clean specialization.

**SkyArc Template Method** — Abstract getters declare the arc shape as pure data; `stops()` is the invariant algorithm. `processStop()` is the hook for subclasses to filter/transform individual stops. Both `Sunlight` and `Moonlight` participate correctly.

**Moonlight.processStop() override** — Uses the hook as intended. Returns `null` to suppress daytime stops. Base `stops()` handles nulls. Correct hook extension.

**Moonlight.stops() calling super.stops()** — Extends (not replaces) the template: super call first, then edge-case additions. Correct cooperative override.

---

## Issue 1 — LSP Smell: `MoonTransit.arrowUp` is semantically vestigial

`Moon` declares `bool get arrowUp` as an abstract member. `Moon.drawIcon()` passes it to `_drawArrow(arrowUp, ...)`. 

`MoonTransit` overrides `drawIcon()` entirely to skip the arrow. It provides `arrowUp = true` only to satisfy the Dart type system — the comment confirms it: `// unused — drawIcon skips the arrow`.

This violates the semantic contract of `Moon`: "all Moon subclasses have a directional arrow." `MoonTransit` does not, but the class hierarchy doesn't express that distinction — it hides it behind an override that silently nullifies the parent's behavior.

**Fix:** Make `arrowUp` nullable. `Moon.drawIcon()` checks before drawing.

```dart
// Moon:
bool? get arrowUp;  // null = no arrow

@override
void drawIcon(Canvas canvas, Size size, double x, double cy) {
  _drawDisc(canvas, x, cy, color, phase);
  final up = arrowUp;
  if (up != null) _drawArrow(canvas, x, cy, up, color);
}

// MoonRise:
@override bool? get arrowUp => true;

// MoonTransit:
@override bool? get arrowUp => null;  // no directional arrow
// drawIcon override is removed entirely

// MoonSet:
@override bool? get arrowUp => false;
```

`MoonTransit.drawIcon()` disappears. The hierarchy now correctly expresses "no arrow" via data instead of via a behavior override that contradicts the parent.

---

## Issue 2 — DRY: `_drawIfVisible` + date-iteration loop duplicated

`SolarMarkerLayer` and `LunarMarkerLayer` share identical code:

```dart
// Duplicated in both:
void _drawIfVisible(Canvas canvas, Size size, AstroObject obj) {
  final x = layout.xForTime(obj.time, now);
  if (x < -kAstroIconRadius || x > size.width + kAstroIconRadius) return;
  obj.draw(canvas, size, x);
}

// Also duplicated — the date iteration loop in paint():
final startLocal = layout.windowStart.toLocal();
final endLocal = layout.windowEnd.toLocal();
var date = DateTime(startLocal.year, startLocal.month, startLocal.day);
final lastDate = DateTime(endLocal.year, endLocal.month, endLocal.day);
while (!date.isAfter(lastDate)) { ... date = date.add(const Duration(days: 1)); }
```

**Fix:** Extract `AstroMarkerLayer` abstract base class.

```dart
abstract class AstroMarkerLayer implements TimelineLayer {
  TimelineLayout get layout;
  DateTime get now;

  List<AstroObject> objectsForDate(DateTime date);

  void _drawIfVisible(Canvas canvas, Size size, AstroObject obj) {
    final x = layout.xForTime(obj.time, now);
    if (x < -kAstroIconRadius || x > size.width + kAstroIconRadius) return;
    obj.draw(canvas, size, x);
  }

  @override
  void paint(Canvas canvas, Size size) {
    var date = DateTime.fromMillisecondsSinceEpoch(
        layout.windowStart.toLocal().millisecondsSinceEpoch)
        .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final lastDate = layout.windowEnd.toLocal();
    while (!date.isAfter(lastDate)) {
      for (final obj in objectsForDate(date)) {
        _drawIfVisible(canvas, size, obj);
      }
      date = date.add(const Duration(days: 1));
    }
  }
}
```

`SolarMarkerLayer` becomes:
```dart
class SolarMarkerLayer extends AstroMarkerLayer {
  // lat, lng, layout, now fields + constructor
  @override
  List<AstroObject> objectsForDate(DateTime date) {
    final times = getSolarTimes(date, lat, lng);
    if (times == null) return const [];
    return [SunRise(time: times.sunrise), Sun(time: times.solarNoon), SunSet(time: times.sunset)];
  }
}
```

`LunarMarkerLayer` becomes:
```dart
class LunarMarkerLayer extends AstroMarkerLayer {
  @override
  List<AstroObject> objectsForDate(DateTime date) {
    final lunar = getLunarTimes(date, lat, lng);
    return [
      if (lunar.moonrise != null) MoonRise(time: lunar.moonrise!, phase: lunar.phase),
      if (lunar.moonset != null) MoonSet(time: lunar.moonset!, phase: lunar.phase),
      if (_transitTime(lunar.moonrise, lunar.moonset) case final t?)
        MoonTransit(time: t, phase: lunar.phase),
    ];
  }
}
```

---

## Design Note (not blocking)

`AstronomicalBackgroundLayer` still receives `AstroData` for solar times and builds `SolarDayTimes` from it, while `SolarMarkerLayer`/`LunarMarkerLayer` compute solar/lunar times directly. This is an architectural inconsistency in data sourcing. It's defensible as a caching trade-off (avoid re-running the binary search for today's events), but worth noting. A future pass could have `AstroData` carry only phase + illumination (badge data), with all solar event times computed in the layers.

---

## Summary

| Item | Status |
|------|--------|
| TimelineLayer usage | ✅ Correct |
| AstroObject Template Method | ✅ Correct |
| Sun→SunRise/SunSet | ✅ Correct |
| SkyArc Template Method | ✅ Correct |
| Moonlight.processStop hook | ✅ Correct |
| Moonlight.stops super-call | ✅ Correct |
| MoonTransit.arrowUp vestigial | ❌ LSP smell — fix: nullable arrowUp |
| _drawIfVisible + date-loop duplication | ❌ DRY violation — fix: AstroMarkerLayer base |
| AstroData dual-computation | ⚠️ Design inconsistency — not blocking |
