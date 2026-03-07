# Happening — Task Board

**Updated**: 2026-03-06 (Sprint 5 v0.2.0 shipped)
**SM**: Mouse

---

## Sprint 1 — Foundation & Shell
*Goal: Working Flutter desktop app with always-on-top strip and mock timeline. No real calendar yet.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S1-01 | Create Flutter project with macOS/Windows/Linux desktop support | Neo | `[x]` |
| S1-02 | Configure `pubspec.yaml` with all dependencies | Neo | `[x]` |
| S1-03 | Implement `WindowService` — always-on-top, frameless, 30px logical height, pinned to screen top | Neo | `[x]` |
| S1-04 | Implement root `HappeningApp` (`StatefulWidget`) — holds auth state, event list, polling timer stub | Neo | `[x]` |
| S1-05 | Implement `ClockService` — `Stream<DateTime>` ticking every second | Neo | `[x]` |
| S1-06 | Implement `TimelineStrip` (`StatelessWidget` + `StreamBuilder`) with `CustomPainter` — render mock events | Neo | `[x]` |
| S1-07 | Implement `NowIndicator` — fixed vertical marker at left-third of strip | Neo | `[x]` |
| S1-08 | Implement `EventBlock` — colored chip with title + start time | Neo | `[x]` |
| S1-09 | Implement `CountdownDisplay` — "38 min" T-minus label between Now and next event | Neo | `[x]` |
| S1-10 | Implement `CelebrationWidget` — end-of-day state (no more events today) | Neo | `[x]` |
| S1-11 | Trin: verify strip appears on top of all windows — `make run` smoke test | Trin | `[x]` |
| S1-12 | Trin: verify mock events scroll left in real time and countdown ticks | Trin | `[x]` |

**Sprint 1 Definition of Done**: App launches, strip is always-on-top, mock events animate left, countdown ticks every second.

---

## Sprint 2 — Google Calendar Integration
*Goal: Real events from Google Calendar. Auth flow complete. Polling live.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S2-01 | Implement `VideoLinkExtractor` — priority chain: hangoutLink → conferenceData → location regex → description regex | Neo | `[x]` |
| S2-02 | Implement `CalendarEvent` model (immutable, includes `videoCallUrl`) | Neo | `[x]` |
| S2-03 | Implement `AuthService` — Google OAuth loopback redirect flow | Neo | `[x]` |
| S2-04 | Implement `TokenStore` — flutter_secure_storage wrapper (store/retrieve/clear tokens) | Neo | `[x]` |
| S2-05 | Implement `CalendarService` — fetch today's events via Google Calendar API v3 (skip all-day events) | Neo | `[x]` |
| S2-06 | Implement `EventRepository` — cache, dedup, sort events | Neo | `[x]` |
| S2-07 | Wire `CalendarService` into `HappeningApp` root state — replace mock events | Neo | `[x]` |
| S2-08 | Implement 5-min polling `Timer` in root `initState` | Neo | `[x]` |
| S2-09 | Implement first-launch auth gate — show OAuth prompt if not authenticated | Neo | `[x]` |
| S2-10 | Trin: end-to-end test — login → real events appear in strip | Trin | `[x]` |
| S2-11 | Trin: verify token refresh works (simulate expired token) | Trin | `[x]` |
| S2-12 | Trin: verify all-day events do NOT appear in strip | Trin | `[x]` |
| S2-13 | Trin: verify video call URL extraction for Meet, Zoom, Teams | Trin | `[x]` |

**Sprint 2 Definition of Done**: Real calendar events display, auth persists across restarts, polling updates within 5 min.

---

## Sprint 3 — Refactor & Polish
*Goal: Decouple services, improve testability, and final UI features.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S3-R01 | Extract `FileTokenStore` and `GoogleAuthService` (Decouple `app.dart`) | Neo | `[x]` |
| S3-R02 | Move hit-testing logic from `TimelineStrip` to `TimelineLayout` | Neo | `[x]` |
| S3-R03 | Add `expand()` and `collapse()` methods to `WindowService` | Neo | `[x]` |
| S3-R04 | Decouple polling loop from `HappeningApp` root state | Neo | `[x]` |
| S3-01 | Implement `HoverDetailOverlay` — full title + GCal link + video call button on hover (F-14) | Neo | `[x]` |
| S3-09 | Implement hover-reveal controls — gear icon + refresh button appear on strip hover (F-20) | Neo | `[x]` |
| S3-10 | Implement `SettingsPanel` popup — opens below strip from gear icon; font/size picker + logout button (F-21, F-22) | Neo | `[x]` |
| S3-11 | Implement logout flow — clear `~/.config/happening/tokens.json`, return to `_AuthState.unauthenticated` (F-22) | Neo | `[x]` |
| S3-12 | Implement font size setting — small/medium/large, persisted to `~/.config/happening/settings.json` (F-21) | Neo | `[x]` |
| S3-13 | Trin: verify settings panel opens/closes, font changes apply live, logout returns to sign-in strip | Trin | `[x]` |
| S3-14 | Implement adaptive tick marks — hour ticks (labeled) + 15-min ticks (unlabeled); density driven by `pixelsPerHour` threshold (F-23) | Neo | `[x]` |
| S3-15 | Implement event start time labels — HH:mm at left edge of event block; suppress if block < 45px or label within 35px of adjacent label (F-24) | Neo | `[x]` |
| S3-16 | Trin: verify tick marks render correctly at narrow/wide windows; verify no overlapping labels | Trin | `[x]` |
| S3-17 | Implement in-meeting countdown mode — detect active event, pass `CountdownMode` to `CountdownDisplay`; amber color for `untilEnd`, white for `untilNext` (F-25) | Neo | `[x]` |
| S3-18 | Trin: verify countdown switches modes correctly — idle→meeting→idle; verify amber/white distinction | Trin | `[x]` |

**Sprint 3 Definition of Done**: Code refactored into decoupled services, all interaction logic unit-tested, hover features complete.

---

## Sprint 4 — Linux Release + Test Pyramid
*Goal: Ship v0.1.0 on Linux (primary). macOS/Windows deferred to v0.2. GPL-3.0 ✅ already committed.*

### Group A — Fix Regressions + Close Sprint 3 QA
| ID | Task | Owner | Status |
|---|---|---|---|
| BUG-09 | Fix: calendar strip not sliding/animating | Neo | `[x]` |
| BUG-10 | Fix: weird box appearing at top of screen (see screenshot 2026-02-27) | Neo | `[x]` |
| BUG-11 | Fix: gear + reload icons not appearing on hover (S3-09 regression) | Neo | `[x]` |
| S3-13 | Trin: verify settings panel opens/closes, font changes live, logout works | Trin | `[x]` |
| S3-16 | Trin: verify tick marks + generate edge-case test data with expected outcomes | Trin | `[x]` |
| S3-18 | Trin: verify countdown modes; CR-02 (countdown position) | Trin | `[x]` |
| S4-08 | Trin: verify refresh button forces live API call (BUG-08) | Trin | `[x]` |

### Group B — Live End-to-End Testing *(creds in app/assets, .gitignored)*
| ID | Task | Owner | Status |
|---|---|---|---|
| S2-10 | Trin: login → real events appear in strip | Trin | `[x]` |
| S2-11 | Trin: verify token refresh + capture raw API JSON to fixture files | Trin | `[x]` |
| S2-12 | Trin: verify all-day events do NOT appear in strip | Trin | `[x]` |
| S2-13 | Trin: verify video URL extraction — Meet ✅; capture Zoom/Teams fixtures | Trin | `[x]` |

### Group C — Test Pyramid
| ID | Task | Owner | Status |
|---|---|---|---|
| S4-15 | Capture raw Google Calendar API responses to JSON fixture files | Neo | `[x]` |
| S4-10 | Unit tests: `SettingsService` (load, update, persist, error fallback) | Neo | `[x]` |
| S4-11 | Widget tests: `SettingsPanel` + fix font sizes (M/L slightly larger, layout scales) | Neo+Trin | `[x]` |
| S4-12 | Hermetic integration: `CalendarController` + mock repo (poll, refresh, forceRefresh) | Neo | `[x]` |
| S4-13 | Headless E2E: hover strip → open settings → change font → close | Trin | `[x]` |
| S4-14 | Headless E2E: logout flow → returns to sign-in strip | Trin | `[x]` |

### Group D — Sprint 4 Feature Work
| ID | Task | Owner | Status |
|---|---|---|---|
| S4-16 | Calendar tasks: show tasks on strip, display time-to-next-task (calendar tasks only, not Google Tasks API) | Neo | `[x]` |
| S4-17 | Enhanced tick marks: 30min half-height + small label, 15min quarter-height + no label; scale with font size | Neo | `[x]` |
| S4-18 | Use calendar event color from API instead of hardcoded blue | Neo | `[x]` |
| S4-19 | Duration labels: show free-time gap between adjacent events (e.g. "45m") on strip | Neo | `[x]` |
| S4-20 | CR-02: Move countdown display to right of now-line | Neo | `[x]` |

### Group F — Visual Regression (Golden File Tests)
*Goal: Catch canvas/paint bugs that semantic tests miss. Uses built-in `matchesGoldenFile` — no new deps.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S4-27 | Fix BUG-13 properly: card MUST left-align to event start and match event width (min 260px) | Neo | `[x]` |
| S4-28 | Verify BUG-14 fix live: cold-restart app; if ticks still invisible, increase height/opacity | Neo+Drew | `[x]` |
| S4-29 | Golden infra: `test/goldens/` dir + `pumpTimelinePainter()` helper with fixed clock + events | Neo | `[x]` |
| S4-30 | Golden test: ticks visible over event blocks (paint order regression) | Neo | `[x]` |
| S4-31 | Golden test: hover card follows mouse X (BUG-13 regression) | Neo | `[x]` |
| S4-32 | Generate goldens (`--update-goldens`) + visual review by Drew (UAT gate) | Trin+Drew | `[x]` |
| S4-33 | Golden UAT: render strip with canned data covering all edge cases (active event, task marker, gap label, tick at window edge, hover card on active event, end-of-day); screenshot each; analyse vs user stories in PRD for pass/fail | Trin | `[x]` |
| S4-34 | Midnight/Month boundary regression test for ticks | Trin | `[x]` |

### Group E — Release
| ID | Task | Owner | Status |
|---|---|---|---|
| S4-03 | Linux: smoke test X11 + Wayland; document `GDK_BACKEND=x11` | Neo | `[x]` |
| S4-04 | README | Oracle | `[x]` |
| S4-05 | GPL-3.0 license | Neo | `[x]` |
| S4-21 | Update task board to reflect final sprint state | Mouse | `[x]` |
| S4-07 | Tag v0.1.0 release on GitHub | Neo | `[x]` |

### Deferred to v0.2
| ID | Task | Reason |
|---|---|---|
| S4-01 | macOS entitlements + OAuth | No Mac hardware |
| S4-02 | Windows OAuth + always-on-top | No Windows hardware |

**Sprint 4 Definition of Done**: Regressions fixed, S3 QA closed, live E2E passing on Linux, test pyramid in place, feature group D shipped, v0.1.0 tagged.

---

## Bug Queue

| ID | Bug | Owner | Status |
|---|---|---|---|
| BUG-04 | Strip appears in center of screen — switched to `GDK_BACKEND=x11` (XWayland); `setPosition()` works | Neo | `[x]` |
| BUG-05 | Window not always-on-top — resolved by `GDK_BACKEND=x11` | Neo | `[x]` |
| BUG-06 | Background transparent when no events — `CelebrationWidget` wrapped in `Container(color: 0xFF1A1A2E)` | Neo | `[x]` |
| BUG-07 | Auth not persisted across restarts — file-based token store in `~/.config/happening/tokens.json` | Neo | `[x]` |
| BUG-08 | Refresh button bypassed 5-min cache — `refresh()` now calls `_fetch(forceRefresh:true)` | Neo | `[x]` |
| BUG-09 | Calendar strip not sliding/animating — regression (2026-02-27) | Neo | `[x]` |
| BUG-10 | Weird box appearing at top of screen — regression (2026-02-27, see screenshot) | Neo | `[x]` |
| BUG-11 | Gear + reload icons not appearing on hover — S3-09 regression (2026-02-27) | Neo | `[x]` |

## Change Requests

| ID | Request | Owner | Status |
|---|---|---|---|
| CR-01 | Move now-line to 10% from left edge (was 15%) | Neo | `[x]` |
| CR-02 | Move countdown remaining-time display to right of now-line | Neo | `[x]` |

---

---

## Sprint 5 — v0.2.0: Multi-Calendar, Themes, Visual Polish, macOS
*Goal: Richer UX — multi-calendar support, themes, configurable window, click-to-expand, visual polish, macOS support.*
*Arch guidance: morpheus.docs/sprint5_arch_review.md | PM scope: cypher.docs/sprint5_assessment.md*

### Group A — Data Model Foundation *(do FIRST — everything depends on this)*
| ID | Task | Owner | Status |
|---|---|---|---|
| [x] S5-A1 | Expand `AppSettings`: add `AppTheme` enum (dark/light/system), `timeWindowHours` (int 8/12/24), `selectedCalendarIds` (List<String>); backward-compatible `fromJson` | Neo | `[x]` |
| [x] S5-A2 | Expand `CalendarEvent`: add `calendarId` (String), `calendarName` (String), `description` (String?), `isCompleted` (bool); extend `copyWith` | Neo | `[x]` |
| [x] S5-A3 | Unit tests: expanded `AppSettings` (toJson/fromJson round-trip, defaults, migration) + `CalendarEvent` new fields | Trin | `[x]` |

### Group B — Settings UI & Theme Infrastructure
| ID | Task | Owner | Status |
|---|---|---|---|
| [x] S5-B1 | Implement `AppTheme` wiring in `MaterialApp`: `StreamBuilder<AppSettings>` → rebuilds `ThemeData`; dark/light/system resolved to concrete Flutter `ThemeData` | Neo | `[x]` |
| [x] S5-B2 | `SettingsPanel`: add theme picker (Dark / Light / System 3-way toggle) | Neo | `[x]` |
| [x] S5-B3 | `SettingsPanel`: add time window picker (8h / 12h / 24h); wire to `TimelineLayout` | Neo | `[x]` |
| [x] S5-B4 | Font sizes +2pt globally (bump `FontSize.px` values: small→11, medium→13, large→15); `WindowService` strip height scales with font setting | Neo | `[x]` |
| [x] S5-B5 | Drop shadow on all text in `TimelinePainter` (event labels, tick labels, countdown) for legibility | Neo | `[x]` |
| [x] S5-B6 | Inject resolved theme colors into `TimelinePainter` constructor (background, pastOverlay, nowLine, tickColor); no `Theme.of(context)` in painter | Neo | `[x]` |
| [x] S5-B7 | Trin: verify theme toggle (all 3 modes), time window picker, font +2pt, strip resizes; update golden files | Trin | `[x]` |

### Group C — Multi-Calendar Data Layer
| ID | Task | Owner | Status |
|---|---|---|---|
| [x] S5-C1 | `CalendarService`: add `fetchCalendarList()` → `List<CalendarMeta>` (id, name, colorHex); populate `calendarId`/`calendarName` on fetched events | Neo | `[x]` |
| [x] S5-C2 | `CalendarService.fetchEvents()`: accept `calendarId` param (default: primary) | Neo | `[x]` |
| [x] S5-C3 | `CalendarController`: fan-out parallel fetch (`Future.wait`) for each `selectedCalendarId`; merge + dedup via existing `EventRepository` | Neo | `[x]` |
| [x] S5-C4 | `SettingsPanel`: calendar selection list (fetch from `CalendarService`; toggle per calendar; persist `selectedCalendarIds` to `AppSettings`) | Neo | `[x]` |
| [x] S5-C5 | Trin: verify multi-calendar fetch (mock 2 calendars), color coding per calendar, selection persists across restart; integration tests with fixture data | Trin | `[x]` |

### Group D — Painter Visual Features
| ID | Task | Owner | Status |
|---|---|---|---|
| [x] S5-D1 | Collision detection: pure function `Set<String> detectCollisions(List<CalendarEvent>)` — any two events whose time ranges overlap | Neo | `[x]` |
| [x] S5-D2 | `TimelinePainter`: draw red outline around colliding event windows; `collidingIds` passed as constructor param (stateless painter) | Neo | `[x]` |
| [x] S5-D3 | Completed tasks render green on strip (check `isCompleted` flag from `CalendarEvent`) | Neo | `[x]` |
| [x] S5-D4 | Time-till label — full spec: (1) uses font size setting, (2) positioned LEFT of now-line rendered on top of past events, (3) color interpolation white→red from 5min; rainbow HSV hue-cycle flash at ≤2min via `AnimationController` in `TimelineStrip` (painter stays stateless — receives resolved `Color`) | Neo | `[x]` |
| [x] S5-D5 | Time-till during event: right-aligned on active event block; counts down to event END | Neo | `[x]` |
| [x] S5-D6 | Trin: verify collision outlines, green tasks, time-till positioning + color progression + flash at 2min; update goldens | Trin | `[x]` |

### Group E — Interaction: Click-to-Expand
| ID | Task | Owner | Status |
|---|---|---|---|
| [x] S5-E1 | `TimelineStrip`: add `GestureDetector` for tap; reuse hover hit-test logic to find tapped `CalendarEvent` | Neo | `[x]` |
| [x] S5-E2 | `HoverDetailOverlay`: add `description` field — HTML-stripped (regex), truncated at ~200 chars; no duplicate event title in card | Neo | `[x]` |
| [x] S5-E3 | Hover card for tasks: show `calendarName` / task list name + truncated `description`; for collision: show conflict note | Neo | `[x]` |
| [x] S5-E4 | Trin: verify tap opens card, description renders (no HTML tags), title not duplicated, task cards show list name | Trin | `[x]` |

### Group F — macOS Platform *(parallel track — Drew has Mac hardware)*
| ID | Task | Owner | Status |
|---|---|---|---|
| [x] S5-F1 | macOS entitlements: `DebugProfile.entitlements` + `Release.entitlements` — com.apple.security.network.client, URL scheme for OAuth callback | Neo | `[x]` |
| [x] S5-F2 | Register OAuth callback URL scheme in `macos/Runner/Info.plist` | Neo | `[x]` |
| [x] S5-F3 | Build on macOS (`flutter build macos`); smoke test: strip top-anchored, always-on-top, OAuth login | Drew+Neo | `[x]` |
| [x] S5-F4 | Trin: macOS verification checklist — strip position, always-on-top, OAuth flow, real events display, hover, settings | Trin | `[x]` |

**Sprint 5 Definition of Done**: Themes shipped (dark/light/system), multi-calendar working with color coding, configurable time window, collision detection visual, completed tasks green, time-till color progression + flash, click-to-expand with clean descriptions, macOS smoke-tested, all tests GREEN, goldens updated, v0.2.0 tagged.

---

## Backlog (V3+)

| ID | Feature | PRD Ref | Note |
|---|---|---|---|
| B-09 | Multiple calendar providers (Outlook, CalDAV) | F-17 | Too big for Sprint 5 |
| B-10 | Multi-account (stackable instances) | F-09 ext | Future sprint |
| B-11 | Windows support | S4-02 | No hardware |

---

*Task board maintained by Mouse. Update status as work progresses.*
