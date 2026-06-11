# Sprint Stories — Linux Reserved Space
*Cypher — 2026-05-16*

## Goal
Reserve screen space on Linux so other windows cannot maximize over the strip,
mirroring the Windows AppBar behavior already implemented in `window_service.dart`.

## Background
- Windows: `SHAppBarMessage` (ABM_NEW/ABM_SETPOS/ABM_REMOVE) registers the strip
  as a system AppBar and carves out a top band from the work area.
- Linux: `ReservedWindowInteractionStrategy` is active but does nothing for strut.
  Other windows can cover the strip area when maximized.
- Fix: Set X11 `_NET_WM_STRUT_PARTIAL` via libX11 FFI, modeled on the Windows code.

---

## User Stories

### US-L1 — Strip does not get covered on Linux
**As a** Linux user in reserved mode,
**I want** maximized windows to stay below the strip,
**so that** I can always see my timeline without it being obscured.

**Acceptance Criteria:**
- AC-L1-1: When the app starts in `WindowMode.reserved`, the strip's height is
  reserved at the top of the primary monitor via `_NET_WM_STRUT_PARTIAL`.
- AC-L1-2: Other windows maximized while the app is running do not cover the strip.
- AC-L1-3: The strut is released when the window mode is changed away from `reserved`.
- AC-L1-4: No regression on Windows (AppBar path unchanged).
- AC-L1-5: No regression on macOS (overlay mode unchanged).

### US-L2 — Strut updates when display changes
**As a** Linux user,
**I want** the reserved band to adjust if I change screen resolution or connect a monitor,
**so that** the reservation stays accurate.

**Acceptance Criteria:**
- AC-L2-1: On `didChangeMetrics`, if Linux + reserved mode, the strut property is
  re-set with the current collapsed height (logical pixels × DPR).
- AC-L2-2: No crash or double-set if display change fires while strut is already set.

### US-L3 — Graceful fallback on Wayland
**As a** Linux user running Wayland,
**I want** the app not to crash if X11 strut is unavailable,
**so that** the app runs safely even without strut support.

**Acceptance Criteria:**
- AC-L3-1: If `DISPLAY` env var is absent or `XOpenDisplay` returns null, the app
  continues without strut (logs a warning, no exception thrown).
- AC-L3-2: Wayland behaviour is identical to current (no strut, strip floats on top).

---

## Out of Scope
- Wayland native strut (requires portal/compositor API — separate sprint).
- Multi-monitor strut (reserve on non-primary monitors).
- Dynamic strip height change while running (strut re-applied on display change only).

---

## Feature ID
F-28: Linux Screen Space Reservation
