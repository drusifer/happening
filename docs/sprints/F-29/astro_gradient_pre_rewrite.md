# Astro Gradient — Pre-Rewrite Record

**Date**: 2026-05-19  
**Status**: Implementation replaced — do not restore this approach

---

## What the old code did

`AstronomicalBackgroundLayer` built a `LinearGradient` with six stops:

| Stop | Color | Time |
|------|-------|------|
| 0 | `_colorAtX(0, …)` | left edge |
| 1 | `_darkNavy` | `civilTwilightBegin` |
| 2 | `_orangePink` | **invented midpoint** `(civilTwilightBegin + sunrise) / 2` |
| 3 | `_skyBlue` | `sunrise` |
| 4 | `_skyBlue` | `sunset` |
| 5 | `_orangePink` | **invented midpoint** `(sunset + civilTwilightEnd) / 2` |
| 6 | `_darkNavy` | `civilTwilightEnd` |
| 7 | `_colorAtX(w, …)` | right edge |

Only stops with pixel position strictly inside `(0, w)` were added between the two edge stops.

---

## Why it was wrong

### 1. Invisible gradient
`_astroDataService.current` is `null` when no location is set. The painter guard `useAstro = isAstroTheme && astroData != null` fell through to the plain `BackgroundLayer`. The astronomical gradient was never painted because there was no user-visible prompt to set a location before selecting the theme.

### 2. Invented midpoints
`midMorning = (xCivilTwilightBegin + xSunrise) / 2` and `midEvening = (xSunset + xCivilTwilightEnd) / 2` are not solar events. Placing the warm-orange peak at an invented midpoint means the color transition happens at arbitrary pixel positions unrelated to actual solar geometry.

### 3. Wrong color at civil twilight begin
The stop at `civilTwilightBegin` was `_darkNavy` — so civil twilight had no visual effect. The orange peak only appeared at the invented midpoint, making `civilTwilightBegin` a no-op stop.

---

## Correct requirements (from user, 2026-05-19)

- The gradient is a **painted texture anchored to solar event times**, scrolling left in real time exactly like tick marks and time labels — the "now" line is fixed; solar events slide toward it.
- Color transitions are tied to the **four actual solar events**: `civilTwilightBegin`, `sunrise`, `sunset`, `civilTwilightEnd`.
- A sun icon appears at the **sunrise** timestamp.
- A sun icon appears at the **sunset** timestamp.
- At any given moment the user sees whatever portion falls in the current time window — could be all night, all day, or the twilight transition sliding in from the right.

---

## Fix: new gradient design

Four stops only — one per actual solar event:

| Stop | Color | Meaning |
|------|-------|---------|
| `civilTwilightBegin` | warm amber `0xFFE8722A` | dawn glow begins here |
| `sunrise` | sky blue `0xFF87CEEB` | full daylight begins here |
| `sunset` | sky blue `0xFF87CEEB` | daylight ends here |
| `civilTwilightEnd` | warm amber `0xFFE8722A` | dusk glow ends here |

Edge colors (x = 0 and x = stripWidth) are determined by `colorAtX(x)` — a pure classifier:

```
x < civilTwilightBegin  →  nightNavy
x < sunrise             →  dawnAmber
x ≤ sunset              →  dayBlue
x ≤ civilTwilightEnd    →  dawnAmber
x > civilTwilightEnd    →  nightNavy
```

`LinearGradient` interpolates between adjacent stops automatically, producing:
- flat dark night before dawn
- smooth warm glow ramp from civilTwilightBegin → sunrise
- flat sky blue through the day
- smooth warm glow ramp from sunset → civilTwilightEnd
- flat dark night after dusk

`colorAtX` is package-visible so unit tests can verify edge behavior without a real Canvas.
