# Current Task

## FETCHING_LAYER_PLAN — 2026-03-23
**Status**: COMPLETE ✅

### Delivered
- [x] `app/lib/features/timeline/painters/fetching_layer.dart` — new TimelineLayer, no-ops when !isLoading
- [x] `timeline_painter.dart` — added isLoading + loadingTextColor params, FetchingLayer appended to compositor stack, shouldRepaint updated
- [x] `timeline_strip.dart` — added isLoading param (default false), threaded to TimelinePainter
- [x] `app.dart` — removed _LoadingStrip, always renders TimelineStrip with isLoading: events == null
- [x] 0 new errors (2 pre-existing unused-var errors in timeline_strip confirmed pre-existing)

### Awaiting
- [ ] Trin UAT
