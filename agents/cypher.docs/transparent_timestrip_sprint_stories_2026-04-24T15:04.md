# Transparent Timestrip Sprint Stories

**Date:** 2026-04-24T15:04
**Persona:** Cypher
**Bloop:** `*plan transparent_timestrip SPRINT`
**Status:** Ready for Smith Gate 1 review

## Sprint Goal

Make Happening visible without trapping the user behind the strip. On macOS the product moves to transparent pass-through mode because reserved desktop space is unreliable. Windows and Linux keep reserved statusbar mode where it works, with transparent mode available as a user setting.

## Scope

### In Scope
- Transparent pass-through mode for the collapsed/idle timeline.
- macOS fixed behavior: transparent pass-through only.
- Windows/Linux setting to choose transparent pass-through or reserved statusbar mode where supported.
- Idle and focused visual states.
- A focus mechanism that makes the timeline opaque and interactive.
- Transparency slider with legibility guardrails.
- Persistent settings and tests.

### Out Of Scope
- Redesigning calendar data sync.
- Replacing existing event layout, countdown, or painter abstractions beyond what transparency requires.
- New calendar providers.
- Full notification/snooze system.

## User Stories

### TT-01 — Idle Timeline Does Not Block My Desktop
As a desktop user, I want the idle timeline to be mostly transparent and pass clicks through to windows behind it, so I can still move, resize, and use app titlebars without fighting Happening.

**Acceptance Criteria**
- macOS idle mode allows pointer interaction with titlebars/windows behind the strip area.
- Idle transparency applies to timeline background, tick marks, and event blocks.
- The now indicator and countdown remain readable at all supported opacity settings.
- Visual depth treatment makes it clear Happening is layered above the desktop.
- The default idle opacity is conservative enough to reveal titlebars while keeping events glanceable.

### TT-02 — I Can Bring Happening Into Focus When I Need Controls
As a user, I want a deliberate focus action to make Happening opaque and interactive, so I can open event details and use settings or refresh without accidental activation.

**Acceptance Criteria**
- Focused mode disables pass-through for interactive controls and event details.
- Focused mode is visually distinct from idle mode.
- Users can leave focused mode through a clear dismissal path such as Escape, clicking away where supported, timeout, or an explicit affordance.
- Settings, refresh, quit, and event-detail interactions are only expected to work when Happening is focused, unless Smith approves a smaller always-clickable target.
- Keyboard-first users have a usable focus path.

### TT-03 — Platform Window Mode Matches What The OS Can Reliably Do
As a user on each desktop OS, I want Happening to use a window mode that works reliably on that platform, so the strip does not block my work or disappear.

**Acceptance Criteria**
- macOS always uses transparent pass-through mode; reserved/statusbar mode is not selectable.
- Windows exposes a persisted mode setting when both transparent and reserved modes are supported.
- Linux exposes a persisted mode setting only when the implementation can verify that pass-through behaves correctly for the current window stack; otherwise it stays in reserved/statusbar mode.
- The UI never offers a selectable mode that is known not to work on the current platform.
- Mode changes apply without corrupting the strip width, height, or always-on-top behavior.

### TT-04 — I Can Tune Transparency Without Making Happening Unreadable
As a user, I want to tune idle transparency, so the strip fits my desktop background and active apps while preserving glanceable schedule awareness.

**Acceptance Criteria**
- Settings include an idle transparency slider with labeled bounds.
- The slider persists across restarts.
- The slider clamps to a product-approved range that keeps countdown, now indicator, and controls legible.
- Preview feedback is visible while adjusting the slider.
- Focused mode remains opaque enough for event details regardless of idle transparency.

### TT-05 — Transparent Mode Does Not Regress Existing Timeline Behavior
As an existing Happening user, I want transparent mode to preserve the timeline information I rely on, so I do not lose countdown accuracy, events, settings, refresh, or theme behavior.

**Acceptance Criteria**
- Countdown and timeline ticking continue at existing cadences.
- Calendar refresh behavior is unchanged.
- Existing settings still load before window initialization.
- Light, dark, and system themes remain usable.
- Existing timeline and settings tests remain green or are updated for intentional visual changes.
- New golden or widget tests cover idle transparent and focused opaque states.

## Open UX Decisions For Smith

- Preferred focus trigger: global hotkey, hover/edge gesture, click target, tray/menu action, or a combination.
- Whether any idle-state element should remain clickable, or whether all interaction requires focus mode.
- Whether macOS should hide reserved/statusbar mode entirely or show it disabled with plain-language rationale.
- Product-approved opacity range for the slider.

## Gate Recommendation

Cypher recommends Smith approve the stories with UX notes, then Morpheus should design the platform abstraction around explicit window modes rather than ad hoc platform conditionals.
