# Painter Refactor Plan — 2026-03-18

## Goal
Break `TimelinePainter` monolith into individual layer types with a common `TimelineLayer` interface.

## Interface

```dart
// lib/features/timeline/painters/timeline_layer.dart
abstract class TimelineLayer {
  void paint(Canvas canvas, Size size, TimelineLayout layout);
}
```

`TimelinePainter.paint()` constructs `TimelineLayout` once, then calls each layer in order.

## Layers (paint order)

| Layer | File | Data (constructor args) |
|-------|------|------------------------|
| `BackgroundLayer` | `background_layer.dart` | `backgroundColor` |
| `PastOverlayLayer` | `past_overlay_layer.dart` | `nowIndicatorX`, `pastOverlayColor` |
| `TickLayer` | `tick_layer.dart` | `windowStart`, `windowEnd`, `now`, `nowIndicatorX`, `fontSize`, `tickColor`, `backgroundColor` |
| `EventsLayer` | `events_layer.dart` | `events`, `now`, `hoveredEventId`, `collidingIds`, `fontSize`, `backgroundColor` |
| `NowIndicatorLayer` | `now_indicator_layer.dart` | `nowIndicatorX`, `nowLineColor` |

**Note**: `EventsLayer` keeps regular events + tasks + gap labels + collision outlines together (same z-order loop, separating would change visual output).

## Shared Utilities

```dart
// lib/features/timeline/painters/timeline_paint_utils.dart
class TimelinePaintUtils {
  static void paintText(Canvas, String, double x, double top, {...})
  static void paintEventLabel(Canvas, String, double x, double top, {...})
  static void paintTaskMarker(Canvas, double x, double endX, double cy, Color, double fontSize)
  static void paintHashFill(Canvas, RRect, Color)
}
```

Used by `TickLayer` and `EventsLayer`.

## TimelinePainter After Refactor

```dart
class TimelinePainter extends CustomPainter {
  TimelinePainter({...}) {  // constructor UNCHANGED
    _layers = [
      BackgroundLayer(backgroundColor: backgroundColor),
      PastOverlayLayer(nowIndicatorX: nowIndicatorX, pastOverlayColor: pastOverlayColor),
      TickLayer(windowStart: windowStart, windowEnd: windowEnd, now: now,
                nowIndicatorX: nowIndicatorX, fontSize: fontSize, tickColor: tickColor,
                backgroundColor: backgroundColor),
      EventsLayer(events: events, now: now, hoveredEventId: hoveredEventId,
                  collidingIds: collidingIds, fontSize: fontSize, backgroundColor: backgroundColor),
      NowIndicatorLayer(nowIndicatorX: nowIndicatorX, nowLineColor: nowLineColor),
    ];
  }

  late final List<TimelineLayer> _layers;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = TimelineLayout(...);
    for (final layer in _layers) {
      layer.paint(canvas, size, layout);
    }
  }

  // shouldRepaint — UNCHANGED
  // semanticsBuilder — UNCHANGED (separate story)
}
```

## File Structure

```
lib/features/timeline/
  painters/
    timeline_layer.dart
    timeline_paint_utils.dart
    background_layer.dart
    past_overlay_layer.dart
    tick_layer.dart
    events_layer.dart
    now_indicator_layer.dart
  timeline_painter.dart   ← imports painters/, composes layers
```

## Constraints
- `TimelinePainter` constructor signature UNCHANGED → zero test breakage
- `shouldRepaint` UNCHANGED
- `semanticsBuilder` UNCHANGED (accepted duplication for now)
- All existing golden tests must pass

## Assign To
@Neo *swe impl PAINTER_REFACTOR_PLAN.md
