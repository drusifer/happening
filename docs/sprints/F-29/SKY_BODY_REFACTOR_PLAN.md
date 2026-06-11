# SkyBody Refactor Plan

## Goal

Replace the `SkyArc`/`Sunlight`/`Moonlight` hierarchy + separate marker layers with a unified
`SkyBody` hierarchy where each body owns both its gradient contribution and its glyph drawing.

---

## Agreed Design

### SkyBody (abstract base)

```dart
abstract class SkyBody {
  Color get upColor;        // body is above horizon
  Color get downColor;      // body is below horizon
  Color get twilightColor;  // transition band color (transparent for moon)
  DateTime? get riseBegin;  // transition starts   (sun: civil twilight begin; moon: moonrise)
  DateTime? get riseEnd;    // fully risen          (sun: sunrise;             moon: moonrise)
  DateTime? get peak;       // highest in sky       (sun: solar noon;          moon: transit)
  DateTime? get setBegin;   // starts setting       (sun: sunset;              moon: moonset)
  DateTime? get setEnd;     // fully set            (sun: civil twilight end;  moon: moonset)

  // Maps times → x coords, builds color ramp: down→twilight→up→up→twilight→down
  List<({double x, Color c})> gradientStops(TimelineLayout layout, DateTime now);

  // Piecewise-linear nightness derived from the same 4 time slots
  double nightnessAt(double x, TimelineLayout layout, DateTime now);

  // Abstract — subclass draws its icon at the given x position
  void drawGlyph(Canvas canvas, Size size, double x, DateTime time);

  // Template: fill gradient + iterate dates and draw glyphs
  void paint(Canvas canvas, Size size, TimelineLayout layout, DateTime now);
}
```

**Gradient color ramp** (built from times → x coords):
```
x < riseBegin  →  downColor
riseBegin..riseEnd  →  downColor → twilightColor → upColor   (mid at midpoint)
riseEnd..setBegin   →  upColor
setBegin..setEnd    →  upColor → twilightColor → downColor   (mid at midpoint)
x > setEnd     →  downColor
```
When `riseBegin == riseEnd` (moon), the transition zone is zero-width — twilightColor stop
is omitted and the switch is instant.

---

### SolarBody extends SkyBody

```
upColor      = dayBlue    (#5BA3C9)
downColor    = nightNavy  (#05080F)
twilightColor = dawnDusk  (#E8722A)
riseBegin  = civilTwilightBegin
riseEnd    = sunrise
peak       = solarNoon
setBegin   = sunset
setEnd     = civilTwilightEnd
```

- `drawGlyph`: draws `SunRise` (at sunrise), `Sun` (at solarNoon), `SunSet` (at sunset)
- `paint`: gradient fill + glyphs + star field (stars scaled by `nightnessAt`)

---

### LunarBody extends SkyBody

```
upColor      = moonlitSky  (Color.lerp(nightNavy, #1A3A80, illumination^0.4))
downColor    = transparent
twilightColor = transparent
riseBegin  = moonrise   (== riseEnd, no transition)
riseEnd    = moonrise
peak       = lunarTransit  (midpoint of moonrise/moonset)
setBegin   = moonset    (== setEnd, no transition)
setEnd     = moonset
```

- Holds a reference to `SolarBody solar`
- `gradientStops`: clips `upColor` to nighttime only — suppresses any stop in
  `[solar.riseEnd .. solar.setBegin]` (daytime window), replacing with transparent
- `drawGlyph`: draws `MoonRise` (at moonrise), `MoonTransit` (at peak), `MoonSet` (at moonset)
- `paint`: gradient fill + glyphs (no stars — solar handles that)

---

## Files Changed

### New / replaced files

| File | Action |
|------|--------|
| `painters/sky_body.dart` | NEW — `SkyBody` abstract base |
| `painters/solar_body.dart` | NEW — replaces `Sunlight` + `SolarMarkerLayer` |
| `painters/lunar_body.dart` | NEW — replaces `Moonlight` + `LunarMarkerLayer` |
| `painters/sky_lights.dart` | DELETE |
| `painters/solar_marker_layer.dart` | DELETE |
| `painters/lunar_marker_layer.dart` | DELETE |
| `painters/astro_marker_layer.dart` | DELETE |
| `painters/astronomical_background_layer.dart` | REWRITE — orchestrates SkyBody instances |

### Modified files

| File | Change |
|------|--------|
| `painters/astro_objects.dart` | Keep (AstroObject icons still used by drawGlyph) |
| `painters/timeline_painter.dart` | Remove SolarMarkerLayer/LunarMarkerLayer from layer list |
| `timeline_strip.dart` | No change expected |

### Test files

| File | Action |
|------|--------|
| `test/painters/solar_body_test.dart` | NEW — replaces solar_marker_layer_test |
| `test/painters/lunar_body_test.dart` | NEW — replaces lunar_marker_layer_test |
| `test/painters/astronomical_background_layer_test.dart` | UPDATE |
| `test/painters/solar_marker_layer_test.dart` | DELETE (or repurpose) |
| `test/painters/lunar_marker_layer_test.dart` | DELETE (or repurpose) |

---

## Implementation Order

1. Create `sky_body.dart` — abstract base with `gradientStops`, `nightnessAt`, `drawGlyph`, `paint`
2. Create `solar_body.dart` — implement all five slots + star field + sun glyphs
3. Create `lunar_body.dart` — implement with `solar` reference + transparent down/twilight + moon glyphs
4. Rewrite `astronomical_background_layer.dart` — creates SolarBody (today+tomorrow) + LunarBody (per day), calls paint on each
5. Update `timeline_painter.dart` — remove SolarMarkerLayer + LunarMarkerLayer from layer list
6. Delete: `sky_lights.dart`, `solar_marker_layer.dart`, `lunar_marker_layer.dart`, `astro_marker_layer.dart`
7. Update tests — replace marker layer tests with body tests
8. `make test` — confirm 355+ green

---

## Key Decisions

- `twilightColor` is a required field (not nullable `mid`) — moon passes `Colors.transparent`
- `LunarBody` receives `SolarBody` as a constructor param — no global state, clean dependency
- Stars stay in `SolarBody.paint` — they are a property of the solar night sky
- `riseBegin == riseEnd` for moon means zero-width transition zone — `gradientStops` skips the
  twilight mid-stop when the two times are equal
- Glyph drawing iterates the same date window as the gradient (windowStart → windowEnd by day)
- `AstronomicalBackgroundLayer` paints solar bodies first (background), lunar on top (overlay)
- `astro_objects.dart` kept as-is — `SunRise`, `Sun`, `SunSet`, `MoonRise`, `MoonTransit`,
  `MoonSet` are still the shapes used by `drawGlyph`

---

## LunarBody.gradientStops — daytime suppression logic

```
for each stop candidate (x, color):
  if color == upColor and x is in [solar.riseEnd .. solar.setBegin]:
    replace color with transparent  (or skip stop)
  else:
    emit stop as-is

also add explicit transparent stops at solar.riseEnd and solar.setBegin
when the moon arc spans the daytime window, so the transition is sharp not gradual
```
