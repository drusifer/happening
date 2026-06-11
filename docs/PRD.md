# PRD: What's Happening? — Always-On Timeline Calendar Strip

**Version**: 0.2
**Author**: Cypher (PM)
**Date**: 2026-02-26
**Status**: Approved — Ready for Architecture & Sprint Planning

## TL;DR
A persistent, horizontal timeline strip for desktop that solves "time blindness" by showing today's events flowing toward a fixed "Now" indicator. Key features: Google Calendar sync, real-time animation, always-on-top visibility, and a countdown to the next event.

---

## 1. Problem Statement

Mainstream calendar apps (Google Calendar, Outlook, Apple Calendar) are powerful but cognitively overwhelming for users with ADHD or "event-based" time perception. These apps present time as a grid — a model that requires users to mentally locate themselves within the grid to answer the single question they actually care about:

> **"What is happening next, and how long until it starts?"**

The result: users must navigate menus, switch views, and interpret dense grids just to answer one simple question — multiple times per day. This creates friction, missed events, and anxiety.

---

## 2. Product Vision

**What's Happening?** is a persistent, always-visible horizontal timeline strip that lives at the top of the screen. It shows exactly one thing: today's events flowing toward a "Now" indicator in real time — so users always know what's next without lifting a finger.

> "The calendar comes to you."

---

## 3. Target Users

| Persona | Description |
|---|---|
| **ADHD User** | Struggles with multi-view calendars; needs immediate, glanceable "what's next" answer |
| **Event-Based Thinker** | Perceives time as a sequence of events, not clock intervals |
| **Busy Professional** | Wants passive awareness of schedule without checking their phone |

**Primary use case**: Users who keep Google Calendar up-to-date but struggle to stay aware of what's coming next throughout the day.

---

## 4. Core Concept

### The Strip

A **narrow, persistent, horizontal bar** anchored to the top of the screen (all platforms). It is:

- Always visible (stays on top, non-intrusive height)
- Non-interactive during normal use (no clicking required)
- Updated in real time

### Layout

```
|←─────── PAST ─────── NOW▼ ─── 38 min ──► [Team Standup 10:00] ──► [Lunch 12:30] ──► ... ─────────────────────────────|
```

- **Now Indicator**: A fixed vertical marker positioned in the left-third of the strip
- **Event Blocks**: Colored blocks representing calendar events, proportionally spaced by time
- **Countdown**: Time remaining until the next upcoming event, displayed prominently near the Now indicator
- **Scroll behavior**: The strip does NOT scroll on user input — it scrolls automatically as real time passes. Events on the right slide leftward toward the Now indicator.

### Time Scale

- **Default view**: Current time ± a configurable window (e.g., 1 hour past, 8 hours future)
- Events are laid out proportionally — a 2-hour gap looks twice as wide as a 1-hour gap
- Distant events compress to fit; nearby events expand to be readable

---

## 5. Feature Requirements

### MVP (Must Have)

| ID | Feature | Description |
|---|---|---|
| F-01 | **Timeline Strip UI** | Persistent horizontal strip at screen top, always on top |
| F-02 | **Google Calendar Integration** | OAuth 2.0 login; read today's events from primary calendar |
| F-03 | **Real-Time Scrolling** | Strip animates continuously; events slide toward Now indicator |
| F-04 | **Now Indicator** | Fixed marker showing current moment |
| F-05 | **Countdown Display** | Prominent "T-minus" display: time until next event |
| F-06 | **Event Blocks** | Color-coded blocks showing event title and time |
| F-07 | **Multiplatform** | Runs on macOS, Windows, Linux (Flutter desktop) |
| F-08 | **Auto-Refresh** | Polls Google Calendar periodically (every 5 min) to pick up new/changed events |

### V2 (Should Have)

| ID | Feature | Description |
|---|---|---|
| F-09 | **Multiple Calendars** | Support multiple Google Calendars; color-coded per calendar |
| F-10 | **Click-to-Expand** | Click event block to see full details |
| F-11 | **Configurable Window** | User sets how many hours of future to display |
| F-12 | **Mobile Support** | Flutter iOS/Android — strip appears as a widget or notification bar |
| F-13 | **Day Boundary Handling** | Celebratory state when no more events today; shows first event tomorrow |
| F-14 | **Hover Detail & Links** | On hover: show full truncated title, link to calendar event, and video call URL (Meet/Zoom/Teams) if present |
| F-20 | **Settings & Refresh Controls** | On hover, reveal gear icon (settings) and refresh button on right side of strip |
| F-21 | **Font/Size Settings** | Configurable event label text size (small/medium/large); persisted to disk |
| F-22 | **Logout / Re-authenticate** | Settings option to clear stored tokens and return to sign-in state (account switching) |
| F-23 | **Tick Marks** | Adaptive hour/minute tick marks along the strip; hour ticks labeled, density scales with available pixel space |
| F-24 | **Event Start Time Labels** | Show HH:mm at the left edge of each event block; suppressed when block is too narrow or labels would overlap |
| F-25 | **In-Meeting Countdown Mode** | When now indicator is inside an active event, countdown shows time until END of current event in amber; normal mode (white) shows time until NEXT event starts |
| F-27 | **Send to Back** | A cross-platform control that temporarily lowers the strip behind all other windows for 10 seconds, then auto-restores always-on-top. Available on all platforms. Re-pressing while sent back resets the 10-second timer. |
| F-28 | **Linux Screen Space Reservation** | Reserve the strip's height at the top of the primary Linux display via `_NET_WM_STRUT_PARTIAL` so maximized windows cannot cover it. Mirrors Windows AppBar behavior. Graceful no-op on Wayland. |
| F-29 | **Astronomical Timeline Theme** | Opt-in theme that overlays sunrise, sunset, moonrise, and moonset markers on the timeline at their exact times for the user's location. Day/night gradient background reflects civil twilight cycle. Moon phase shown with 8-phase icon set. All astronomical data calculated offline via Dart astronomy library (no external API). Location via `geolocator` package with manual lat/lng fallback. |
| F-30 | **Multi-Monitor Support** | User can choose which display the strip lives on (single strip, single chosen display). Per-monitor DPI respected. Survives monitor hot-plug: falls back to primary on disconnect, auto-returns when reconnected. F-28 strut reservation generalized to chosen Linux display. One-strip-per-monitor and cursor-follow are explicitly out of scope. See `agents/cypher.docs/f30_multi_monitor_stories.md`. |
| F-31 | **Timestrip Hide / Show** ✅ SHIPPED | ← button on the far-left edge hides the strip, leaving only a mini countdown + → button anchored top-left. Tapping → or the countdown restores the full strip. Linux strut and Windows AppBar reservations are released on hide and re-acquired on show. 300ms Flutter animation; OS window resizes once per transition. See `docs/sprints/F-31/` for sprint artifacts. |

### V3 (Nice to Have)

| ID | Feature | Description |
|---|---|---|
| F-15 | **Snooze / Focus Mode** | Temporarily collapse strip |
| F-16 | **Themes** | Light/dark/system; custom accent colors |
| F-17 | **Multiple Calendar Providers** | Outlook, Apple Calendar, CalDAV |
| F-18 | **Sound/Notification Alerts** | Optional chime N minutes before events |
| F-19 | **Collision Detection** | Detect overlapping events; visual indicator highlighting the conflict and nudging user to resolve |


---

## 6. Non-Requirements (Explicitly Out of Scope)

- Creating, editing, or deleting calendar events (read-only for MVP)
- Full calendar views (month, week, agenda) — this is NOT a calendar app replacement
- Event RSVP management
- Task/to-do integration (V3+ if ever)

---

## 7. User Stories

### US-01 — See What's Next (Core)
> As a user with ADHD, I want to glance at the top of my screen and immediately see what event is coming up next and how long until it starts, so I can stay on track without opening my calendar.

**Acceptance Criteria**:
- Strip is visible at all times on the primary display
- The next upcoming event is always visible to the right of the Now indicator
- A countdown (e.g., "38 min") is displayed between Now and the next event
- Updates every second (countdown) and every 5 minutes (event data)

### US-02 — Authenticate with Google Calendar
> As a user, I want to log in with my Google account so my real calendar events appear in the strip.

**Acceptance Criteria**:
- App triggers OAuth 2.0 flow on first launch
- Token is stored securely and refreshed automatically
- User can revoke/re-authenticate from settings

### US-03 — See Today's Full Schedule at a Glance
> As a user, I want to see all of today's remaining events laid out proportionally on the strip so I can understand how my day is structured.

**Acceptance Criteria**:
- All future events for today are visible on the strip (may require horizontal scrolling for dense days)
- Events are spaced proportionally to actual time gaps
- Event blocks show at minimum: title, start time

### US-04 — Real-Time Progression
> As a user, I want the strip to animate in real time so I never have to manually refresh or update my view.

**Acceptance Criteria**:
- Strip position updates continuously (smooth or per-second tick)
- Now indicator stays fixed; event blocks move left
- No user interaction required for the strip to stay current

### US-05 — Multiplatform Launch
> As a user, I want to run this on my Mac, Windows PC, or Linux machine so I can use whichever computer I'm on.

**Acceptance Criteria**:
- App builds and runs on macOS, Windows, Linux
- Strip anchors to top of primary display on all platforms
- Window stays on top of other applications

### US-06 — Temporarily Move the Strip Out of the Way
> As a desktop user, I want a way to temporarily move the timeline strip out of the way so I can access windows behind it, without having to close the app.

**Acceptance Criteria**:
- A "send to back" button is visible in the strip on all platforms (macOS, Windows, Linux).
- Pressing the button lowers the strip behind all other windows and clears always-on-top for 10 seconds.
- After 10 seconds the strip automatically returns to always-on-top without stealing focus.
- The button shows an active/highlighted state while the strip is sent back.
- Re-pressing the button while the strip is sent back resets the 10-second timer.
- Restoring to front does not bring the strip into focus or disrupt the user's current active window.

---

## 8. Technical Constraints & Decisions

| Item | Decision | Rationale |
|---|---|---|
| **Framework** | Flutter (desktop + mobile) | Single codebase, multiplatform, strong animation support |
| **Auth** | OAuth 2.0 (Google) | Required by Google Calendar API |
| **Calendar API** | Google Calendar REST API v3 | Official, well-documented |
| **Always-on-top** | Floating window (KISS) | Flutter desktop supports this via window_manager package; no OS taskbar integration needed for MVP |
| **Window Sizing** | DPI-adaptive height | Strip height scales with screen DPI for crisp rendering on HiDPI/4K displays |
| **Window Mode** | Reserved (always-on-top, opaque strip) on all platforms | Transparent pass-through was attempted across macOS, Windows, and Linux; no platform delivered a reliable implementation. Reserved mode is stable everywhere. |
| **Send to Back** | Button lowers strip behind other windows for 10 s, then auto-restores | Replaces click-through; cross-platform; no platform-specific plumbing required |
| **Token Storage** | flutter_secure_storage | OS-native secure credential storage |
| **All-Day Events** | Not displayed | Out of scope — no meaningful time position on timeline |
| **End-of-Day State** | Celebratory UI | When no more events remain today, show a celebratory animation/message |

---

## 9. Success Metrics

| Metric | Target |
|---|---|
| Time-to-answer "what's next?" | < 1 second glance (zero interaction) |
| Event refresh latency | ≤ 5 minutes from calendar change |
| Countdown accuracy | ± 1 second |
| Platforms supported at launch | macOS, Windows, Linux |

---

## 10. Open Questions

All resolved. ✅

| # | Question | Answer | Resolved By |
|---|---|---|---|
| OQ-1 | Fixed pixel height or DPI-adaptive? | DPI-adaptive — looks great on all screens | Drew |
| OQ-2 | All-day events? | Not displayed — no meaningful time position | Drew |
| OQ-3 | No more events today? | Celebratory state | Drew |
| OQ-4 | OS widget vs floating window? | Floating window (KISS) | Drew |
| OQ-5 | Open source vs commercial? | Open source | Drew |

---

---

## 11. License

Open source. License TBD (MIT recommended).

---

*Approved by Drew 2026-02-26. Ready for: @Morpheus *arch review + @Mouse *sm plan*
