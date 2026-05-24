# Neo Context — 2026-05-24

## Current State
F-29 Astronomical Timeline Theme — complete. Lint cleanup sprint — COMPLETE.

## Lint cleanup (2026-05-24) — ALL DONE

### What was fixed (session 2)
12 lint-metrics warnings cleared:
- TextPaintConfig + EventLabelConfig introduced to reduce paintText/paintEventLabel params
- AstronomicalBackgroundLayer.hitTest converted to instance method (7→2 params)
- _verifySecureStorage() extracted from _initServices (reduces nesting 6→5)
- _GradCtx context class introduced for LunarBody gradient helpers (avoids param bloat)
- LunarBody.gradientStops split into _patternBStops/_addPatternAStops/_addPostDuskStops
- AstronomicalBackgroundLayer._buildLunarBodies extracted (reduces _buildBodies complexity)
- EventsLayer.paint split into 5 helpers; RRect passed to avoid >6 params
- TickLayer.paint split into _paintHalfAndQuarterTicks + _paintFiveMinuteTicks
- _handleMouse split: _computeEventBoundsMap + _findHoveredEvent extracted
- _TimelineStripState.build refactored: outer build → _buildLayout → 6 child helpers
- _SettingsPanelState.build: 3 column helpers + slider labels + calendar list
- _AstroLocationSectionState.build: 3 List<Widget> section helpers

### Final lint state
- make lint-style: PASS
- make lint-format: PASS
- make lint-metrics: PASS (0 issues)
- make test: 352/352 green

## F-29 Sprint architecture (unchanged)
- AstronomicalBackgroundLayer → SkyBody → SolarBody + LunarBody
- Each body owns gradient stops + glyphs
- AstroDataService in _TimelineStripState.initState()
- Solar times: UTC DateTimes from binary search; solar noon is local
- Hover tooltip: use hit.time.toLocal() for display

## Key patterns introduced
- _GradCtx: context record pattern for methods that need many pre-computed values without param bloat
- Instance method hitTest on ABL instead of static with many named params
- Column helpers in settings returning Widget (not List<Widget>) to keep build clean
- Section helpers in _AstroLocationSectionState returning List<Widget> (for spread in Column children)

## Important constraints
- NEVER use Opacity widget on Linux (GTK regression → use canvas.saveLayer+BlendMode.dstIn)
