# Sprint 4 — Tech Lead Guidance
**Date**: 2026-02-28
**Author**: Morpheus

---

## Priority Order (non-negotiable)

```
1. Fix regressions (BUG-09/10/11)   ← nothing else until these are green
2. Painter pass (S4-17/18/19/20)    ← one cohesive painter refactor
3. Calendar tasks (S4-16)           ← model + service + painter
4. Test pyramid (S4-10 to S4-15)    ← run alongside features
```

---

## BUG-09/10/11 — Regression Diagnosis

All three regressions point at **`timeline_strip.dart`**. The hover state
refactor in S3-09 introduced `_onMouseMove` / `_windowService` calls that
interact badly with the `StreamBuilder` rebuild cycle.

### BUG-09 — Strip Not Sliding

**Hypothesis**: `_windowService.collapse()` is being called too aggressively
during mouse moves, causing the window resize to interfere with the
`ClockService` stream or trigger excessive rebuilds that stall animation.

**Where to look**: `_onMouseMove` — specifically the path where `hit == null`
and `_hoveredEvent != null`. That path calls `collapse()` + `setState()` on
every mouse move over empty space. With rapid mouse moves this may be
swamping the render thread.

**Fix direction**: Gate `collapse()` calls — only call if the window is
*currently expanded*. Track `_isExpanded` state to avoid redundant resize ops.

### BUG-10 — Box at Top

**Hypothesis**: The `HoverDetailOverlay` or `SettingsPanel` is rendering at
`top: _kCollapsedHeight` (30px) but the window is collapsed (30px tall), so
the overlay overflows *above* the window bounds and reappears as a ghost
artifact. The `Stack(clipBehavior: Clip.none)` confirms this — overflow is
intentional but the window size and widget visibility may be out of sync.

**Fix direction**: Ensure `_hoveredEvent` and `_isSettingsOpen` are both
`false` whenever the window is in collapsed state. Add an assertion or guard
in `_onMouseExit`.

### BUG-11 — No Gear/Reload Icons

**Hypothesis**: `_isHoveringStrip` is never being set to `true`, or it's
being reset before the hover controls render. The `MouseRegion.onEnter`
sets `_isHoveringStrip = true` but `_onMouseExit` resets it to `false`.
If window resizing (from BUG-09/10) triggers a spurious exit event, the
hover controls immediately disappear.

**Fix direction**: Fix BUG-09 first. The chain is: aggressive collapse →
mouse exit event → `_isHoveringStrip = false` → icons gone.
All three bugs share a root cause.

### Root Cause Summary

> `_windowService.collapse()` is called too eagerly. Each call resizes
> the OS window, which can trigger a pointer-exit event, which clears
> `_isHoveringStrip`, which removes the hover controls, which breaks
> the animation loop. Fix: track `_isExpanded` and skip redundant collapse calls.

---

## Painter Pass — S4-17/18/19/20 (do as ONE PR)

All four tasks touch `TimelinePainter`. Do them together — opening and
closing the painter four times invites merge conflicts and inconsistent
state. One cohesive pass, one PR.

### S4-20 — Countdown Position (CR-02) → move to `timeline_strip.dart`

The countdown `Positioned` widget in `timeline_strip.dart` is at:
```dart
right: stripWidth - nowIndicatorX + 8,  // LEFT of now-line
```
Change to:
```dart
left: nowIndicatorX + 8,  // RIGHT of now-line
```
Simple — no painter change needed. Do this first.

### S4-17 — Enhanced Tick Marks → `TimelinePainter`

Current: hour ticks (full height, labeled) + 15-min ticks (unlabeled).
Target:
```
Hour tick:   full height, labeled                    ← existing
30-min tick: half height, small label (e.g. ":30")  ← new
15-min tick: quarter height, no label               ← replaces old 15-min
```
**Architecture**: Add a `TickDensity` enum or just use the existing
`pixelsPerHour` threshold. Scale tick heights proportionally, not with
magic numbers. Font size from `SettingsService` should drive label size.

### S4-18 — Event Colors → `TimelinePainter` + `CalendarEvent`

`CalendarEvent` already has a `color` field. `TimelinePainter` currently
ignores it and uses a hardcoded blue. Fix: pass `event.color` to the
`paint.color` call. One-liner per event block. Do it in the same painter pass.

### S4-19 — Duration Labels Between Events → `TimelinePainter`

**Architecture**: In the painter's `paint()` loop, after drawing all event
blocks, do a second pass over adjacent event pairs:
```
for each (eventA, eventB) where eventB.start > eventA.end:
  gapStart = xForTime(eventA.end)
  gapEnd   = xForTime(eventB.start)
  gapWidth = gapEnd - gapStart
  if gapWidth > 40px: draw centered label "Xm"
```
Keep it purely in the painter — no model change needed. Suppress if gap < 40px.

---

## Calendar Tasks — S4-16

### Decision: Extend `CalendarEvent`, Don't Create a New Type

KISS. Add `isTask: bool = false` to `CalendarEvent`. Tasks render
differently on the strip (e.g., a diamond marker instead of a block)
but share all the same time/title/color data.

```dart
@immutable
class CalendarEvent {
  // ... existing fields ...
  final bool isTask;  // ADD THIS
}
```

**`CalendarService`**: Google Calendar Tasks that appear on the calendar
are just events with `eventType == 'task'` (or in the Tasks API). Drew
confirmed: only tasks *on the calendar* — these show up in the Calendar
API as events with a special type. Filter + map them alongside regular events.

**`TimelinePainter`**: Render tasks as a small diamond/tick at their due
time rather than a block. No duration (tasks are point-in-time).

**Countdown**: If the next upcoming item is a task, show countdown to it.
`CalendarEvent.isTask` makes this transparent — no countdown logic change needed.

---

## Test Pyramid Architecture — S4-10 to S4-15

### Fixture Strategy (OQ-14 resolved: deterministic + repeatable)

```
app/test/fixtures/
  calendar_response_normal.json     ← typical day, mix of events
  calendar_response_empty.json      ← no events
  calendar_response_all_day.json    ← all-day events to verify filtering
  calendar_response_tasks.json      ← tasks on calendar
  calendar_response_video_links.json ← Meet/Zoom/Teams events
```

Neo captures these from the live API (S4-15). Trin writes tests against them.

### Layer Summary

```
Unit (fast, no Flutter):
  SettingsService — load/save/defaults
  EventRepository — cache logic, dedup
  TimelineLayout  — pixel math (already tested)
  VideoLinkExtractor — pattern matching (already tested)

Integration (Flutter, mocked services):
  CalendarController — poll/refresh/forceRefresh with FakeEventRepository
  SettingsPanel widget — GestureDetector taps → SettingsService calls
  TimelineStrip — hover state machine (mock WindowService)

E2E headless (integration_test):
  Full app boot → sign-in strip (no creds)
  Hover → controls appear → open settings → change font
  Logout flow
```

### Key Interface: `FakeCalendarService`

```dart
class FakeCalendarService implements CalendarService {
  final List<CalendarEvent> events;
  FakeCalendarService(this.events);
  @override
  Future<List<CalendarEvent>> fetchTodayEvents() async => events;
}
```

This already works because `CalendarService` is abstract. Neo just
needs to write `FakeCalendarService` once and all integration tests share it.

---

## `timeline_strip.dart` — Complexity Warning

It is doing too much:
1. Clock stream management
2. Mouse hover state
3. Window resize orchestration
4. Layout geometry
5. Hover card positioning
6. Settings panel visibility

**Not blocking Sprint 4** but flag for Sprint 5 refactor. Consider:
- Extract `_HoverController` (manages hover state + window expand/collapse)
- This would also fix the race condition at the root of BUG-09/10/11 properly

---

## Sprint 4 Work Order for Neo

```
Day 1: Fix BUG-09/10/11 (root cause: _isExpanded guard in timeline_strip)
Day 2: Painter pass (CR-02 + S4-17 + S4-18 + S4-19)
Day 3: Calendar tasks (S4-16 model + service + painter)
Day 4: S4-15 fixture capture + S4-10/S4-12 unit/integration tests
Day 5: S4-03 Linux smoke test + S4-07 tag
```
