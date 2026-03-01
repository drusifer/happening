# Sprint 4 Plan — Linux Release + Test Pyramid
**Date**: 2026-02-28
**Author**: Cypher (PM)
**Integrated**: Drew's notes 2026-02-27

---

## Sprint 4 Goal

> Ship a stable, tested v0.1.0 on **Linux (primary)**. macOS/Windows deferred to v0.2. Build full test pyramid. GPL-3.0 license already committed.

---

## Open Questions — ALL RESOLVED ✅

| # | Question | Answer |
|---|---|---|
| OQ-8 | License type? | GPL-3.0 — `LICENSE` file already committed in project root ✅ |
| OQ-9 | OAuth creds for live testing? | `app/assets/client_secret.json` exists, .gitignored ✅ |
| OQ-10 | GDK_BACKEND=x11 OK for v0.1.0? | Yes — X11 is fine for now ✅ |
| OQ-13 | Calendar tasks scope? | **Sprint 4** — show calendar tasks, display time-to-next-task ✅ |
| OQ-14 | E2E test strategy? | Deterministic + repeatable — capture raw API JSON to fixture files; no live calls in tests ✅ |
| OQ-15 | GitHub repo? | Repo already exists ✅ |

---

## Active Regressions (NEW — from Drew's testing 2026-02-27)

| ID | Bug | Evidence |
|---|---|---|
| BUG-09 | Calendar not sliding / animating anymore | Drew observed |
| BUG-10 | Weird box appearing at top of screen | Screenshot: `Screenshot From 2026-02-27 23-55-16.png` |
| BUG-11 | No gear icon + no reload icon on hover | Drew observed (S3-13 regression) |

> **Priority**: BUG-09/10/11 must be fixed before any Group A QA can close.

---

## Sprint 4 Tasks

### Group A — Fix Regressions + Close Sprint 3 QA

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| BUG-09 | Fix: calendar not sliding/animating | Neo | `[ ]` | Regression — investigate ClockService / StreamBuilder |
| BUG-10 | Fix: weird box at top of screen | Neo | `[ ]` | See screenshot 2026-02-27 23-55-16 |
| BUG-11 | Fix: gear + reload icons not appearing on hover | Neo | `[ ]` | S3-09 regression |
| S3-13 | Trin: verify settings panel, font live-update, logout | Trin | `[ ]` | Blocked on BUG-11 fix |
| S3-16 | Trin: verify tick marks + generate edge-case test data with expected outcomes | Trin | `[ ]` | |
| S3-18 | Trin: verify countdown mode + **move remaining time to right of now-line** | Trin | `[x]` | Drew verified ✅; CR-02 logged for position change |
| S4-08 | Trin: verify refresh button forces live API call | Trin | `[x]` | Drew verified ✅ |

### Group B — Live End-to-End Testing

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| S2-10 | Trin: login → real events appear in strip | Trin | `[ ]` | Creds in `app/assets/` (.gitignored) |
| S2-11 | Trin: verify token refresh (expired token sim) + capture raw API JSON to fixture files | Trin | `[ ]` | Log responses so regression tests can replay without live session |
| S2-12 | Trin: verify all-day events not in strip | Trin | `[x]` | Drew verified ✅ |
| S2-13 | Trin: verify video URL extraction (Meet ✅, Zoom, Teams) | Trin | `[x]` | Meet verified via regression tests ✅; Zoom/Teams still need captured fixtures |

### Group C — Test Pyramid

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| S4-10 | Unit tests: `SettingsService` (load, update, persist, error fallback) | Neo | `[ ]` | |
| S4-11 | Widget tests: `SettingsPanel` (font tap → update, logout) + fix font sizes (M/L slightly larger, layout scales) | Trin+Neo | `[ ]` | Pre-configured fixture data; no live calls |
| S4-12 | Hermetic integration: `CalendarController` + mock repo (poll, refresh, forceRefresh) | Neo | `[ ]` | Partially covered — top up |
| S4-15 | Capture raw Google Calendar API responses to JSON fixture files | Neo | `[ ]` | Enables deterministic replay for all integration tests |
| S4-13 | Headless E2E: hover strip → open settings → change font → close | Trin | `[ ]` | `integration_test` package; fixture backend |
| S4-14 | Headless E2E: logout flow → returns to sign-in strip | Trin | `[ ]` | `integration_test` package |

### Group D — Sprint 4 Feature Work

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| S4-16 | Calendar tasks: show tasks from Google Calendar; display time-to-next-task on strip | Neo | `[ ]` | Tasks already on calendar (not Google Tasks API) |
| S4-17 | Enhanced tick marks: 30min (half-height, small label), 15min (quarter-height, no label); all sizes scale with font setting | Neo | `[ ]` | Hour ticks full-height + label (existing); extend density |
| S4-18 | Use calendar event color (from API) instead of hardcoded blue | Neo | `[ ]` | `CalendarEvent` already has `color` field |
| S4-19 | Duration labels: show gap duration between adjacent events (e.g. "45m free") | Neo | `[ ]` | New visual element on strip |
| S4-20 | Move countdown remaining-time display to **right** of now-line (CR-02) | Neo | `[ ]` | Currently left of now-line |

### Group E — Linux Platform & Release

| ID | Task | Owner | Status | Notes |
|---|---|---|---|---|
| S4-03 | Linux: smoke test X11 + Wayland; document `GDK_BACKEND=x11` workaround | Neo | `[ ]` | |
| S4-04 | README (setup, OAuth credentials, build instructions) | Oracle | `[x]` | ✅ DONE |
| S4-05 | GPL-3.0 license | Neo | `[x]` | ✅ Already committed in `LICENSE` |
| S4-21 | Update task.md to reflect final sprint state | Mouse | `[ ]` | |
| S4-07 | Tag v0.1.0 release on GitHub | Neo | `[ ]` | Final task |

### Deferred to v0.2

| ID | Task | Reason |
|---|---|---|
| S4-01 | macOS entitlements + OAuth | No Mac hardware |
| S4-02 | Windows OAuth + always-on-top | No Windows hardware |

---

## Change Requests

| ID | Request | Notes |
|---|---|---|
| CR-02 | Move countdown display to right of now-line | Drew: "move the remaining time to the right of the now line as a visual cue" |

---

## Sprint 5 Plan (revised)

| ID | Feature | Status | Notes |
|---|---|---|---|
| S5-03 | Stackable multi-instance (each with own auth + config) + single-account multi-calendar | IN | KISS approach |
| S5-04 | Collision detection: highlight overlapping events | IN | "+1, simply highlight" |
| S5-05 | Themes: dark / light / system (in Settings) | IN | Drew added |
| ~~S5-01~~ | Day boundary | REMOVED | "nix this" |
| ~~S5-02~~ | Configurable time window | REMOVED | "over complicated" |
| ~~S5-06~~ | Calendar tasks | MOVED to Sprint 4 | Drew: "I want this for Sprint 4" |

---

## Sprint 4 Definition of Done

- BUG-09/10/11 fixed and verified
- S3-13, S3-16 QA closed
- Live E2E passing on Linux (S2-10, S2-11, S2-13 Zoom/Teams)
- API fixture files captured for deterministic replay
- Test pyramid in place (unit + integration + E2E)
- Calendar tasks visible on strip
- Enhanced tick marks, event colors, duration labels, countdown position shipped
- GPL-3.0 ✅, README ✅, v0.1.0 tagged
