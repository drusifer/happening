# F-30 — Multi-Monitor Support — User Stories

**Feature ID:** F-30
**PRD Tier:** V2 (post-MVP)
**Author:** Cypher (PM)
**Date:** 2026-05-29
**Status:** READY — Smith Gate 1 APPROVED 2026-05-29; AC updated with Notes 1-3, 5; awaiting Morpheus arch (Gate 2)

---

## Problem Statement

Today the strip is hard-wired to the **primary display**. Users with dual or multi-monitor setups
(very common among the focused/productivity audience this app targets) cannot:

- Move the strip to a non-primary display
- Have the strip respect per-monitor DPI/work-area on the display they actually use
- Recover gracefully when a monitor is disconnected/reconnected (laptop dock workflow)
- Reserve space (F-28 strut) on a display other than primary on Linux

Internal probe: `screen_retriever` and `window_manager` are already in `pubspec.yaml`, so the
underlying capability exists. PRD currently says "anchors to top of primary display on all
platforms" — this is the V1 simplification we're now relaxing.

---

## Goals

1. Let the user choose **which display** the strip lives on
2. Survive monitor hot-plug (disconnect/reconnect, dock/undock) without manual fix-up
3. Each chosen display keeps its full anchoring guarantees (always-on-top, F-28 strut on
   Linux, AppBar on Windows, top edge of *that* display's work area)
4. Respect per-monitor DPI for the strip's height/scaling

## Non-Goals (V2 scope guard)

- **One strip per monitor** — out of scope for V2; revisit if users ask. Single strip, single chosen
  display.
- **Auto-follow cursor / active window** — out of scope; explicit user choice only.
- **Span across monitors** — out of scope; strip stays on exactly one display.

---

## User Stories

### US-F30-1 — Choose which display the strip lives on

**As a** user with multiple monitors,
**I want to** pick which display the strip appears on,
**so that** it sits where I actually look (not always the primary).

**Acceptance Criteria:**
- Settings has a "Display" control listing all **currently-connected** displays
- **Display labels — explicit fallback chain (per Smith Gate 1 Note 2, 2026-05-29):**
  1. If `screen_retriever` returns an OS display name that is **non-empty**, **non-generic**
     (excludes "Generic PnP Monitor", "Unknown Display", "Default Monitor", and similar
     placeholder strings), and **unique** within the current display set → use the OS name
     (e.g., `"Dell U2723QE"`)
  2. Otherwise → fall back to `"Display N — {width}×{height}"` (e.g., `"Display 2 — 1920×1080"`)
     so users can still distinguish displays
  3. The primary display always carries a `" — primary"` suffix in either form (e.g.,
     `"Dell U2723QE — primary"` or `"Display 1 — primary"`)
- **Disconnected-display behavior in picker (per Smith Gate 1 Note 3, 2026-05-29):**
  - Picker shows only currently-connected displays as selectable rows
  - If the user's persisted choice is currently disconnected, show a separate read-only row
    at the bottom: `"Currently set: Display 2 — unavailable"` so the user understands why
    their chosen display isn't in the active list
  - No "pre-pick a disconnected display" affordance — users may only select from connected
- Selecting a different display moves the strip to the top of that display's work area within
  500ms, no app restart required. **Live switch on change** — user identifies displays by the
  strip jumping when they change the selection (no separate flash-to-test affordance needed).
- Selection persists across app restarts
- Default on first launch: primary display (current behavior, no regression)
- Strip's top edge aligns to top of the **chosen** display's work area, not the desktop
  bounding rect (i.e., respects per-display taskbar/dock on Windows/macOS)
- No keyboard shortcut or tray quick-action for "move to display N" (Settings-only — OQ-4
  resolved 2026-05-29)

### US-F30-2 — Per-monitor DPI is respected

**As a** user whose displays have different DPI (e.g., 4K laptop + 1080p external),
**I want** the strip to render crisply on whichever display it's on,
**so that** text isn't blurry or comically small/large when I move it.

**Acceptance Criteria:**
- Strip height scales using the chosen display's DPI scale factor (per Smith Gate 1 Note 5,
  2026-05-29):
  - Flutter `MediaQueryData.devicePixelRatio` for the strip's window matches the **chosen**
    display's OS-reported DPI scale factor, not the primary display's
  - Verified pass/fail at the four most common scale factors during UAT: **100% (1.0x),
    125% (1.25x), 150% (1.5x), 200% (2.0x)**
- Moving the strip from a low-DPI to a high-DPI display (US-F30-1) re-scales without restart
- Verified on at least one mixed-DPI setup during UAT

### US-F30-3 — Survive monitor disconnect / reconnect

**As a** laptop user who docks/undocks,
**I want** the strip to do the right thing when my external monitor goes away,
**so that** I don't lose access to it and don't have to re-configure every time.

**Acceptance Criteria:**
- If the chosen display is disconnected while the app is running, the strip falls back to the
  current primary display automatically:
  - **≤2s** on X11 / Windows / macOS (event-driven via `screen_retriever`)
  - **≤7s** on Wayland (per Smith Gate 2 Note B 2026-05-29 — Wayland uses a polling fallback
    because compositor hot-plug events are not reliably surfaced; matches F-28's graceful
    Wayland-degradation posture)
- **Fallback indicator MUST appear on the strip itself, not buried in Settings (per Smith
  Gate 1 Note 1 MUST-FIX, 2026-05-29).** Concrete requirement:
  - When the persisted chosen display is unavailable and the strip is in fallback mode, a
    visible indicator appears on the strip itself — at-a-glance, no clicks required
  - Acceptable forms (Morpheus to pick one concrete design): (a) a warning glyph adjacent to
    the settings gear with tooltip "Chosen display unavailable — showing on primary",
    (b) a colored top-border / accent stripe along the strip edge, or (c) a colored
    dot/badge on the settings gear itself
  - The Settings panel additionally surfaces a more detailed message (e.g., "Currently set:
    Display 2 — unavailable") but Settings cannot be the only indicator
  - Rationale: silently overriding the user's display choice breaks Heuristic #1 (Visibility
    of System Status) and the feature's user contract ("strip lives on the display I picked")
- When the original chosen display reconnects, the strip **automatically returns** to it
  immediately, with no user interaction required (OQ-1 resolved 2026-05-29 — "it should
  auto return immediately without a user interaction"). The user's persisted preference is
  the source of truth, not the fallback.
- If the chosen display is gone at app *startup*, the app launches on primary with the same
  indicator shown
- No crashes, no off-screen window, no zero-size window in any disconnect/reconnect sequence

### US-F30-4 — Linux strut reservation works on the chosen display

**As a** Linux X11 user who wants the strip on my second monitor,
**I want** maximized windows on **that** monitor to respect the strip's space,
**so that** F-28's screen-space reservation guarantee still holds when I'm not on primary.

**Acceptance Criteria:**
- `_NET_WM_STRUT_PARTIAL` is set with `strut_partial` start/end coordinates that correspond to
  the **chosen** display's x-range within the virtual desktop, not just the primary display's range
- Verified: maximize a window on the chosen display → it stops at strip's bottom edge, not at
  display top
- Verified: maximize on a *different* (non-chosen) display → window uses full height of that
  display (strip doesn't steal space from displays it isn't on)
- Wayland: graceful no-op (matches existing F-28 behavior)
- **Windows AppBar moves with selection** (OQ-3 resolved 2026-05-29 — "it should move the strut
  from the primary display to the one that is selected"). AppBar registers against the chosen
  display. If Win32 AppBar API does not natively support binding to a non-primary monitor,
  Morpheus to design a workaround (e.g., unregister + re-register AppBar with the chosen
  display's work-area bounds) — but the *behavior* is non-negotiable: maximized windows on the
  chosen display must respect the strip's space, regardless of which display is chosen.

---

## Open Questions for Drew — ALL RESOLVED 2026-05-29

| # | Question | Why it matters | Owner | Drew's Answer |
|---|----------|----------------|-------|---------------|
| OQ-1 | When the chosen display reconnects after disconnect, should the strip auto-return immediately, or wait for next user action? | Affects US-F30-3 AC; auto-return is more "it just works" but could be jarring mid-meeting | Drew |  it should auto return immediately without a user interaction |
| OQ-2 | Identify displays in Settings by index ("Display 1/2/3"), by resolution, by OS-reported name, or by a "click here to test" flash on the actual display? | UX clarity vs. implementation complexity; Smith likely has opinions | Drew + Smith |  use the os reported name if that is available otherwise display one two three etc.  changing the setting should switch it to the desire to display so it should be pretty easy to figure out which is which |
| OQ-3 | Windows AppBar — if the Win32 AppBar API only binds to primary, is it acceptable to ship multi-monitor without strut-equivalent reservation on Windows secondary displays (i.e., maximized windows can cover the strip on secondary)? | Determines Windows scope; may need a follow-up F-30b | Drew + Morpheus |  it should move the strut from the primary display ah to the one that is selected |
| OQ-4 | Should there be a quick "move strip to display N" keyboard shortcut / tray action, or is Settings-only acceptable? | Power-user ergonomics; small scope add | Drew |  settings  acceptable to not introduce keyboard shortcuts |

---

## Out-of-Scope (Explicit)

- Multiple simultaneous strips (one per display)
- Cursor-follow / active-window-follow auto-switching
- Strip spanning two displays
- Picture-in-picture / portable mini-strip mode

These may become separate features post-F-30 if user demand emerges.

---

## Dependencies & Risks

- **F-28 Linux Reserved Space**: strut math currently assumes primary display; F-30 requires
  generalizing the strut x-range computation. Morpheus to confirm scope.
- **Windows AppBar API**: unclear if AppBar can bind to non-primary monitor. May force scope
  reduction on Windows (OQ-3).
- **`screen_retriever` reliability**: hot-plug events on Linux X11 vs Wayland vs Windows vs
  macOS need verification; package is already in pubspec but its event coverage hasn't been
  exercised at this depth.
- **DPI re-scaling mid-session**: Flutter's MediaQuery handles this for in-window content; need
  to confirm the *window-level* sizing also re-flows when moving displays.

---

## Gate Plan

1. **Drew answers OQ-1..4** (blocks all gates below)
2. **Smith HCI review** of stories (US-F30-1/-2/-3/-4) — focus on Settings discoverability
   and disconnect-indicator UX
3. **Morpheus arch**:
   - Generalize work-area / DPI lookup per chosen display
   - Strut math generalization (F-28 dependency)
   - Hot-plug event subscription & fallback state machine
   - Windows AppBar non-primary feasibility study
4. **Mouse sprint plan** after arch lands

---

*Last updated: 2026-05-29 — Cypher*
