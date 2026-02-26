# Happening — Task Board

**Updated**: 2026-02-26
**SM**: Mouse

---

## Sprint 1 — Foundation & Shell
*Goal: Working Flutter desktop app with always-on-top strip and mock timeline. No real calendar yet.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S1-01 | Create Flutter project with macOS/Windows/Linux desktop support | Neo | `[x]` |
| S1-02 | Configure `pubspec.yaml` with all dependencies | Neo | `[x]` |
| S1-03 | Implement `WindowService` — always-on-top, frameless, 52px logical height, pinned to screen top | Neo | `[x]` |
| S1-04 | Implement root `HappeningApp` (`StatefulWidget`) — holds auth state, event list, polling timer stub | Neo | `[x]` |
| S1-05 | Implement `ClockService` — `Stream<DateTime>` ticking every second | Neo | `[x]` |
| S1-06 | Implement `TimelineStrip` (`StatelessWidget` + `StreamBuilder`) with `CustomPainter` — render mock events | Neo | `[x]` |
| S1-07 | Implement `NowIndicator` — fixed vertical marker at left-third of strip | Neo | `[x]` |
| S1-08 | Implement `EventBlock` — colored chip with title + start time | Neo | `[x]` |
| S1-09 | Implement `CountdownDisplay` — "38 min" T-minus label between Now and next event | Neo | `[x]` |
| S1-10 | Implement `CelebrationWidget` — end-of-day state (no more events today) | Neo | `[x]` |
| S1-11 | Trin: verify strip appears on top of all windows — `make run` smoke test | Trin | `[ ]` |
| S1-12 | Trin: verify mock events scroll left in real time and countdown ticks | Trin | `[ ]` |

**Sprint 1 Definition of Done**: App launches, strip is always-on-top, mock events animate left, countdown ticks every second.

---

## Sprint 2 — Google Calendar Integration
*Goal: Real events from Google Calendar. Auth flow complete. Polling live.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S2-01 | Implement `VideoLinkExtractor` — priority chain: hangoutLink → conferenceData → location regex → description regex | Neo | `[ ]` |
| S2-02 | Implement `CalendarEvent` model (immutable, includes `videoCallUrl`) | Neo | `[ ]` |
| S2-03 | Implement `AuthService` — Google OAuth loopback redirect flow | Neo | `[ ]` |
| S2-04 | Implement `TokenStore` — flutter_secure_storage wrapper (store/retrieve/clear tokens) | Neo | `[ ]` |
| S2-05 | Implement `CalendarService` — fetch today's events via Google Calendar API v3 (skip all-day events) | Neo | `[ ]` |
| S2-06 | Implement `EventRepository` — cache, dedup, sort events | Neo | `[ ]` |
| S2-07 | Wire `CalendarService` into `HappeningApp` root state — replace mock events | Neo | `[ ]` |
| S2-08 | Implement 5-min polling `Timer` in root `initState` | Neo | `[ ]` |
| S2-09 | Implement first-launch auth gate — show OAuth prompt if not authenticated | Neo | `[ ]` |
| S2-10 | Trin: end-to-end test — login → real events appear in strip | Trin | `[ ]` |
| S2-11 | Trin: verify token refresh works (simulate expired token) | Trin | `[ ]` |
| S2-12 | Trin: verify all-day events do NOT appear in strip | Trin | `[ ]` |
| S2-13 | Trin: verify video call URL extraction for Meet, Zoom, Teams | Trin | `[ ]` |

**Sprint 2 Definition of Done**: Real calendar events display, auth persists across restarts, polling updates within 5 min.

---

## Sprint 3 — Polish & Ship
*Goal: Hover details, platform configs, open source release.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S3-01 | Implement `HoverDetailOverlay` — full title + GCal link + video call button on hover (F-14) | Neo | `[ ]` |
| S3-02 | macOS: entitlements (`NSAppTransportSecurity`, network client), Info.plist OAuth config | Neo | `[ ]` |
| S3-03 | Windows: Google OAuth client config, test always-on-top | Neo | `[ ]` |
| S3-04 | Linux: test on X11 + Wayland (GNOME), document Wayland limitation if any | Neo | `[ ]` |
| S3-05 | Write README (setup, OAuth credentials, build instructions) | Oracle | `[ ]` |
| S3-06 | Add MIT license | Neo | `[ ]` |
| S3-07 | Trin: regression test all S1+S2 acceptance criteria on all 3 platforms | Trin | `[ ]` |
| S3-08 | Tag v0.1.0 release | Neo | `[ ]` |

**Sprint 3 Definition of Done**: App ships on all 3 platforms, open source on GitHub, documented.

---

## Backlog (V2+)

| ID | Feature | PRD Ref |
|---|---|---|
| B-01 | Multiple Google Calendars + color coding | F-09 |
| B-02 | Configurable time window (F-11) | F-11 |
| B-03 | Day boundary handling → show tomorrow's first event | F-13 |
| B-04 | Mobile (Flutter iOS/Android) | F-12 |
| B-05 | Collision detection (F-19) | F-19 |
| B-06 | Snooze/Focus mode (F-15) | F-15 |
| B-07 | Themes: light/dark/system (F-16) | F-16 |
| B-08 | Sound/notification alerts (F-18) | F-18 |
| B-09 | Multiple calendar providers (F-17) | F-17 |

---

*Task board maintained by Mouse. Update status as work progresses.*
