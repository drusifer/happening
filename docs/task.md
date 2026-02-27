# Happening — Task Board

**Updated**: 2026-02-27
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
| S2-10 | Trin: end-to-end test — login → real events appear in strip | Trin | `[ ]` |
| S2-11 | Trin: verify token refresh works (simulate expired token) | Trin | `[ ]` |
| S2-12 | Trin: verify all-day events do NOT appear in strip | Trin | `[ ]` |
| S2-13 | Trin: verify video call URL extraction for Meet, Zoom, Teams | Trin | `[ ]` |

**Sprint 2 Definition of Done**: Real calendar events display, auth persists across restarts, polling updates within 5 min.

---

## Sprint 3 — Refactor & Polish
*Goal: Decouple services, improve testability, and final UI features.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S3-R01 | Extract `FileTokenStore` and `GoogleAuthService` (Decouple `app.dart`) | Neo | `[ ]` |
| S3-R02 | Move hit-testing logic from `TimelineStrip` to `TimelineLayout` | Neo | `[ ]` |
| S3-R03 | Add `expand()` and `collapse()` methods to `WindowService` | Neo | `[ ]` |
| S3-R04 | Decouple polling loop from `HappeningApp` root state | Neo | `[ ]` |
| S3-01 | Implement `HoverDetailOverlay` — full title + GCal link + video call button on hover (F-14) | Neo | `[x]` |
| S3-09 | Implement hover-reveal controls — gear icon + refresh button appear on strip hover (F-20) | Neo | `[ ]` |
| S3-10 | Implement `SettingsPanel` popup — opens below strip from gear icon; font/size picker + logout button (F-21, F-22) | Neo | `[ ]` |
| S3-11 | Implement logout flow — clear `~/.config/happening/tokens.json`, return to `_AuthState.unauthenticated` (F-22) | Neo | `[ ]` |
| S3-12 | Implement font size setting — small/medium/large, persisted to `~/.config/happening/settings.json` (F-21) | Neo | `[ ]` |
| S3-13 | Trin: verify settings panel opens/closes, font changes apply live, logout returns to sign-in strip | Trin | `[ ]` |
| S3-14 | Implement adaptive tick marks — hour ticks (labeled) + 15-min ticks (unlabeled); density driven by `pixelsPerHour` threshold (F-23) | Neo | `[ ]` |
| S3-15 | Implement event start time labels — HH:mm at left edge of event block; suppress if block < 45px or label within 35px of adjacent label (F-24) | Neo | `[ ]` |
| S3-16 | Trin: verify tick marks render correctly at narrow/wide windows; verify no overlapping labels | Trin | `[ ]` |
| S3-17 | Implement in-meeting countdown mode — detect active event, pass `CountdownMode` to `CountdownDisplay`; amber color for `untilEnd`, white for `untilNext` (F-25) | Neo | `[ ]` |
| S3-18 | Trin: verify countdown switches modes correctly — idle→meeting→idle; verify amber/white distinction | Trin | `[ ]` |

**Sprint 3 Definition of Done**: Code refactored into decoupled services, all interaction logic unit-tested, hover features complete.

---

## Sprint 4 — Platform & Release
*Goal: macOS/Windows support and shipping.*

| ID | Task | Owner | Status |
|---|---|---|---|
| S4-01 | macOS: entitlements (`NSAppTransportSecurity`, network client), Info.plist OAuth config | Neo | `[ ]` |
| S4-02 | Windows: Google OAuth client config, test always-on-top | Neo | `[ ]` |
| S4-03 | Linux: test on X11 + Wayland (GNOME), document Wayland limitation if any | Neo | `[ ]` |
| S4-04 | Write README (setup, OAuth credentials, build instructions) | Oracle | `[x]` |
| S4-05 | Add MIT license | Neo | `[ ]` |
| S4-06 | Trin: regression test all S1+S2 acceptance criteria on all 3 platforms | Trin | `[ ]` |
| S4-07 | Tag v0.1.0 release | Neo | `[ ]` |

**Sprint 4 Definition of Done**: App ships on all 3 platforms, open source on GitHub, documented.

---

## Bug Queue

| ID | Bug | Owner | Status |
|---|---|---|---|
| BUG-04 | Strip appears in center of screen — switched to `GDK_BACKEND=x11` (XWayland); `setPosition()` works | Neo | `[x]` |
| BUG-05 | Window not always-on-top — resolved by `GDK_BACKEND=x11` | Neo | `[x]` |
| BUG-06 | Background transparent when no events — `CelebrationWidget` wrapped in `Container(color: 0xFF1A1A2E)` | Neo | `[x]` |
| BUG-07 | Auth not persisted across restarts — file-based token store in `~/.config/happening/tokens.json` | Neo | `[x]` |

## Change Requests

| ID | Request | Owner | Status |
|---|---|---|---|
| CR-01 | Move now-line to 10% from left edge (was 15%) | Neo | `[x]` |

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
