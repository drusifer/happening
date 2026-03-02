# Sprint 5 — Architecture Review
**Date**: 2026-03-01
**Author**: Morpheus (Tech Lead)
**Input**: cypher.docs/sprint5_assessment.md, current codebase (SettingsService, CalendarEvent)

---

## TL;DR

Sprint 5 is architecturally sound but has one cross-cutting dependency: **Themes (S5-05) must establish its infrastructure first**, or every other feature will be implemented without theme-awareness and require a rework pass. Beyond that, the implementation order falls naturally into 6 groups.

---

## Feature-by-Feature Complexity

| ID | Feature | Complexity | Key Architectural Concern |
|----|---------|------------|--------------------------|
| S5-05 | Themes | **High** | Cross-cutting — touches every widget + CustomPainter |
| S5-03 | Multi-Calendar | **Medium** | CalendarService fan-out + AppSettings calendar list |
| S5-T3 | Time-till color shift | **Medium** | Color interpolation + animation in CustomPainter |
| S5-T4 | Completed tasks → green | **Medium** | Need `isCompleted` + `description` on CalendarEvent; depends on task API |
| S5-10 | macOS Support | **Medium** | Entitlements, OAuth URL scheme, parallel track |
| S5-04 | Collision Detection | **Low-Med** | Pure logic + painter flag; easy after multi-cal |
| S5-06 | Click-to-Expand | **Low** | Reuse hover hit-test; HTML strip regex |
| S5-09 | Configurable Time Window | **Low** | AppSettings field → TimelineLayout injection |
| S5-T1 | Font +2pt + strip resize | **Low** | Bump FontSize.px values; WindowService height |
| S5-T2 | Drop shadow on text | **Low** | TextPainter shadow param |
| S5-T5 | Overlap red outline | **Low** | Painter flag from S5-04 collision set |

---

## Architectural Decisions

### DEC-S5-01: Themes — Use Flutter ThemeData + Injected Painter Colors

**Problem**: `TimelinePainter` is a `CustomPainter` — it cannot call `Theme.of(context)`.

**Decision**:
1. Add `AppTheme` enum to `AppSettings` (`dark` / `light` / `system`).
2. `MaterialApp` wraps in `StreamBuilder<AppSettings>` → rebuilds `ThemeData` on change.
3. `TimelineStrip` resolves `AppTheme` → concrete colors → passes them as constructor params to `TimelinePainter`.
4. All other widgets use `Theme.of(context)` normally.

**No global singletons. No InheritedWidget for painter — constructor injection only.**

---

### DEC-S5-02: AppSettings — Single Expansion (do once)

**Current** `AppSettings` has only `fontSize`. Sprint 5 adds 3 new fields. Do them all at once:

```dart
class AppSettings {
  const AppSettings({
    this.fontSize = FontSize.medium,
    this.theme = AppTheme.dark,           // S5-05
    this.timeWindowHours = 8,             // S5-09 (8/12/24)
    this.selectedCalendarIds = const [],  // S5-03 (empty = all)
  });
  // toJson / fromJson extended accordingly
}
```

**Rule**: `AppSettings.fromJson` must be backward-compatible (all new fields have defaults). Existing `settings.json` files must not break.

---

### DEC-S5-03: CalendarEvent — Model Additions (do once)

Add 3 fields to `CalendarEvent`:

```dart
final String calendarId;      // S5-03: which calendar this belongs to
final String calendarName;    // S5-03/T4: for hover card display
final String? description;    // S5-06/T4/T5: truncated in hover card
final bool isCompleted;       // S5-T4: completed tasks → green
```

All new fields have defaults. `copyWith` extended. No breaking changes.

---

### DEC-S5-04: Multi-Calendar — Fan-Out in CalendarController

**Current**: `CalendarController` fetches single primary calendar.

**Proposed**:
1. `CalendarService` gains `fetchCalendarList()` → returns `List<CalendarMeta>` (id, name, color).
2. `CalendarController` fans out: fetches events for each `selectedCalendarId` in parallel (`Future.wait`).
3. Merges and deduplicates by event ID (existing `EventRepository` logic covers this).
4. `SettingsPanel` gains a calendar picker (list of toggles from `fetchCalendarList()`).

---

### DEC-S5-05: Collision Detection — Pure Function + Painter Flag

```dart
// Pure function, fully testable:
Set<String> detectCollisions(List<CalendarEvent> events) { ... }
```

`TimelineStrip` computes this set after receiving events, passes it to `TimelinePainter`. Painter draws red outline when `collidingIds.contains(event.id)`. No state in painter.

---

### DEC-S5-06: Time-Till Color (S5-T3) — Interpolation in Painter

Color progression logic:
- `> 5 min` → white
- `5 min → 2 min` → linear interpolation white → red
- `≤ 2 min` → rainbow flash (cycle hue via `HSVColor` + animation ticker)

`TimelineStrip` owns the `AnimationController` for the flash. Passes a resolved `Color` to `TimelinePainter` each frame. **Painter stays stateless.**

---

### DEC-S5-07: macOS — Parallel Track

macOS is platform configuration, not feature code. Can proceed in parallel:
1. `macos/Runner/DebugProfile.entitlements` + `Release.entitlements` — network + URL scheme
2. OAuth callback URL scheme registration in `Info.plist`
3. `window_manager` already supports macOS — minimal changes
4. Manual smoke test by Drew on his Mac

**Assign to Neo as a dedicated task group (Group F), independent of feature groups.**

---

## Recommended Implementation Order

### Group A — Foundation (do FIRST, everything depends on this)
- Expand `AppSettings` (theme, timeWindow, selectedCalendars) [S5-05, S5-09, S5-03]
- Expand `CalendarEvent` (calendarId, calendarName, description, isCompleted) [S5-03, S5-06, S5-T4]

### Group B — Settings UI
- Theme picker in SettingsPanel [S5-05]
- Time window picker (8h/12h/24h) [S5-09]
- Font size bump +2pt + strip height resize [S5-T1]
- `MaterialApp` ThemeData wiring [S5-05]

### Group C — Multi-Calendar Data Layer
- `CalendarService.fetchCalendarList()` [S5-03]
- `CalendarController` fan-out + merge [S5-03]
- Calendar toggles in SettingsPanel [S5-03]

### Group D — Painter Visual Features
- Drop shadow on text [S5-T2]
- Collision detection pure function + red outline [S5-04 + S5-T5]
- Completed tasks → green [S5-T4]
- Time-till label: position + color shift + flash [S5-T3]

### Group E — Interaction
- Click-to-expand: tap detection + HTML strip + description in card [S5-06]

### Group F — macOS (Parallel)
- Entitlements, URL scheme, smoke test [S5-10]

---

## Risk Register

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Themes breaks all golden tests | High | Update goldens in same PR as theme implementation |
| macOS OAuth callback URL scheme config tricky | Medium | Use existing Linux OAuth pattern; refer to Flutter OAuth docs |
| Calendar tasks `isCompleted` not in current API fixture | Medium | Add to fixture + update CalendarService parser |
| Time-till rainbow flash causes repaint storm | Low | Ticker only active when ≤ 2min to event |
| Sprint scope too large | Medium | Groups A-B-C are highest value; D-E-F are stretch |

---

## Verdict

Sprint 5 is **approved with ordering constraint**: Group A (data model expansion) must ship before Groups B-E. macOS (F) is parallel. If velocity is a concern, Groups D-E are stretch. Core value is in Groups A-C.

*@Mouse *sm plan — use this ordering for the Sprint 5 board.*
