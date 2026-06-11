# F-29 Sprint Stories — Astronomical Timeline Theme
*Cypher — 2026-05-18*

## Goal

Add an "Astronomical" theme option that overlays sunrise, sunset, moonrise, and moonset
markers on the timeline, with a day/night gradient background reflecting the actual sky
cycle at the user's location. Moon phase is displayed correctly for the current date.

---

## Background

The strip is a time-scale display. Astronomical events (sunrise, sunset, moonrise,
moonset) have precise daily times that can be pinned to exact positions on that scale —
making the strip a natural fit for showing the rhythm of the day alongside calendar events.

**Data sources:**

| Data | Source | Notes |
|------|--------|-------|
| Sunrise, sunset, solar noon, civil twilight begin/end | Dart astronomy library | Calculated locally from lat/lng + date; no network call |
| Moonrise, moonset, moon phase, illumination % | Dart astronomy library | Same library, same offline calculation |
| OS device location | `geolocator` Flutter package | macOS, Windows, Linux (GeoClue2); fallback to manual entry if denied |

No external APIs required. All astronomical data is computed offline from coordinates and date.

---

## Decisions (OQs Resolved — 2026-05-18)

| # | Question | Decision |
|---|----------|----------|
| OQ-1 | Moon data source | **Dart astronomy library** — offline, no network dep |
| OQ-2 | Gradient depth | **Civil twilight** — transitions at civil twilight begin/end |
| OQ-3 | Off-screen moon markers | **Always show static moon phase badge**; rise/set icons only when in visible window |
| — | Solar data source | **Dart astronomy library** — all astronomical data offline; no external APIs |
| — | Location API | **`geolocator` Flutter package** — in settings panel for current device location |

---

## User Stories

### US-F29-1 — Location Setup

**As a** user who wants to see astronomical events on the timeline,
**I want** to configure my location once in settings,
**so that** sunrise/sunset/moon times are accurate for where I actually am.

**Acceptance Criteria:**

- AC-F29-1-1: Settings panel shows a "Location" section when the Astronomical theme is enabled.
- AC-F29-1-2: The settings location section includes a "Use Current Location" button
  powered by the `geolocator` Flutter package. When tapped and permission is granted,
  the device's current coordinates are fetched and saved automatically. A "Using device
  location" label confirms this; the user can override with manual coordinates at any time.
- AC-F29-1-3: Manual entry accepts decimal latitude (−90 to 90) and longitude (−180 to 180).
  Invalid values are rejected with an inline error message.
- AC-F29-1-4: A location preview shows city/region name resolved from coordinates (reverse
  geocode via the OS or a bundled lookup table). If resolution fails, coordinates are
  shown as-is.
- AC-F29-1-5: Location is persisted to app settings and survives app restart.
- AC-F29-1-6: If no location is configured and OS location is unavailable/denied, the
  Astronomical theme shows a settings prompt in the strip: "Set location to see
  sunrise & moon times." Tapping the strip opens the settings location section.

---

### US-F29-2 — Solar Events on the Timeline

**As a** user with the Astronomical theme active,
**I want** to see sunrise and sunset marked on the timeline at the correct times,
**so that** I can plan around natural light without leaving the strip.

**Acceptance Criteria:**

- AC-F29-2-1: When the Astronomical theme is selected, a sunrise icon (🌅 or custom SVG)
  appears at the exact timeline position corresponding to today's civil twilight begin
  (start of dawn). A sunset icon appears at civil twilight end (end of dusk).
- AC-F29-2-2: The timeline background renders a day/night gradient:
  - Before civil twilight begin → dark (night)
  - civil twilight begin → sunrise → warm orange/pink gradient
  - Sunrise → sunset → sky-blue or light tint (day)
  - Sunset → civil twilight end → warm orange/pink gradient
  - After civil twilight end → dark (night)
  The gradient applies only within the visible time window; it scrolls with the strip.
- AC-F29-2-3: A secondary solar noon marker (small tick or sun icon) is shown at solar
  noon time.
- AC-F29-2-4: Solar markers do not overlap or obscure calendar event blocks. They render
  behind event blocks in z-order.
- AC-F29-2-5: Solar data is calculated locally via the Dart astronomy library once per
  calendar day per location and cached in memory for the session. No network call is made.
  The only prerequisite is a saved location (lat/lng); if none is set, AC-F29-1-6 applies.
- AC-F29-2-6: No regression: when the Astronomical theme is not selected, the timeline
  renders identically to the current default theme.

---

### US-F29-3 — Lunar Events on the Timeline

**As a** user with the Astronomical theme active,
**I want** to see moonrise and moonset marked on the timeline with the correct moon phase,
**so that** I can track the lunar cycle as part of my day.

**Acceptance Criteria:**

- AC-F29-3-1: All lunar data (moonrise time, moonset time, moon phase, illumination %)
  is calculated locally using the Dart astronomy library from the saved lat/lng and
  today's date. No network call is made for lunar data.
- AC-F29-3-2: A moon icon at the correct moon phase (8-phase model: new, waxing crescent,
  first quarter, waxing gibbous, full, waning gibbous, last quarter, waning crescent)
  appears at the timeline position for today's moonrise time, if moonrise falls within
  the visible time window.
- AC-F29-3-3: A matching moon icon (same phase, dimmer or outlined style to indicate
  setting) appears at today's moonset time, if moonset falls within the visible window.
- AC-F29-3-4: If moonrise or moonset falls outside the visible time window, its icon is
  not shown; no overflow artifact.
- AC-F29-3-5: A small static moon phase badge is always shown at the far right of the
  strip (near the settings gear), displaying tonight's phase name and illumination
  percentage — regardless of whether moonrise/moonset are in the visible window.
- AC-F29-3-6: Lunar calculations run once per calendar day per location and are cached
  in memory for the session. No offline fallback needed (no network dep).

---

### US-F29-4 — Theme Selection

**As a** user,
**I want** to enable or disable the Astronomical theme from settings,
**so that** the feature is opt-in and does not affect my current visual experience.

**Acceptance Criteria:**

- AC-F29-4-1: Settings panel adds a "Theme" section with at minimum two options:
  "Default" and "Astronomical". (This scaffolds F-16 Themes.)
- AC-F29-4-2: Switching to Astronomical theme triggers a location check (US-F29-1) before
  applying the theme. If location is already saved, it applies immediately.
- AC-F29-4-3: Switching back to Default removes all astronomical markers and gradients
  from the strip without requiring a restart.
- AC-F29-4-4: Theme selection persists across app restarts.

---

## Out of Scope

- Wayland-specific location services (GeoClue2 is the target; exact fallback behavior TBD by Morpheus).
- Southern-hemisphere polar day/polar night edge cases (V4+).
- Astronomical twilight gradient layer (nautical and astronomical twilight — too subtle at strip height).
- Multiple-day forecast of solar/lunar events.
- Interactive click-to-details on solar/lunar markers (V4+).
- Custom location names / saved location profiles.

---

## Feature ID

F-29: Astronomical Timeline Theme

## PRD Section

V2 (Should Have) — moves from V3 F-16 Themes skeleton into concrete sub-feature.

## Dependencies

- F-20 (Settings & Refresh Controls) — settings panel must exist ✓ shipped
- `geolocator` Flutter package — add to `pubspec.yaml`; OS permissions config for macOS, Windows, Linux
- Dart astronomy library — Morpheus to select specific pub.dev package (e.g., `astronomy`, `moon_phase`, or custom port)
- No external API dependencies — fully offline after location is saved

---

## Smith Review Gate

Stories must pass Smith (HCI/UX) review before architecture begins.
Specific UX concerns to validate:
- Is the gradient subtle enough to not distract from calendar events?
- Is the location prompt (AC-F29-1-6) non-intrusive?
- Is the 8-phase moon icon set legible at strip height (~28–36px)?
- Does the static moon phase badge clutter the strip or complement it?
