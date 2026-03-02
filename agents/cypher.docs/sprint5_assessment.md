# Sprint 5 Assessment — FINALIZED Feature Scope
**Date**: 2026-03-01
**Author**: Cypher (PM)
**Status**: FINAL — Drew reviewed and approved all items below.

---

## Sprint 4 Baseline (v0.1.0 SHIPPED ✅)

All PRD MVP features (F-01–F-08) shipped.
V2 features shipped: F-13, F-14, F-20, F-21, F-22, F-23, F-24, F-25.
Group D extras shipped: calendar tasks on strip, enhanced ticks, event colors from API, duration labels, countdown position.

---

## Sprint 5 Confirmed Scope — v0.2.0

### Feature Stories

| ID | Feature | Drew's Decision | Notes |
|----|---------|----------------|-------|
| **S5-03** | Multi-Calendar | ✅ IN | Single Google account; multiple calendars selectable in Settings; color-coded per calendar from API |
| **S5-04** | Collision Detection | ✅ IN | Red outline around the conflicting time window; task/event hover card shows list name + truncated description |
| **S5-05** | Themes | ✅ IN | Dark / Light / System toggle in Settings; persisted to settings.json |
| **S5-06** | Click-to-Expand | ✅ IN | Show truncated event details; strip HTML formatting; no duplicate event name (already shown on block) |
| **S5-09** | Configurable Time Window | ✅ REINSTATED | 3 options in Settings: 8h / 12h / 24h. Previous removal reversed by Drew. |
| **S5-10** | macOS Support | ✅ IN | Drew now has Mac hardware. macOS entitlements + OAuth flow. |

### Visual / UX Tweaks

| ID | Description | Drew's Direction |
|----|-------------|-----------------|
| **S5-T1** | Font sizes +2pt globally | Resize strip height accordingly |
| **S5-T2** | Drop shadow on text | Improve legibility over event blocks |
| **S5-T3** | Time-till label — 4 behaviors | See spec below |
| **S5-T4** | Completed tasks → green | Task list name + truncated description in hover card |
| **S5-T5** | Overlapping events → red outline | Around the conflicting window; not just border on block |

### S5-T3: Time-Till Label Spec (Drew)
1. **Uses font size setting** — scales with user's chosen font size
2. **Before event**: rendered LEFT of now-line, on top of past events/tasks for legibility
3. **Progressive color shift**: white → red as event approaches; flashing rainbow at ≤ 2 min
4. **During event**: right-aligned on the active event block; counts down to END of event

---

## Permanently Dropped (Drew's Decision)

| ID | Feature | Reason |
|----|---------|--------|
| F-12 | Mobile Support | "Doesn't make sense on a phone" |
| F-15 | Snooze / Focus Mode | "This app is literally for people who are too focused — it would defeat the purpose" |
| F-18 | Sound / Notification Alerts | Dropped |

---

## Backlog (Future Sprints)

| ID | Feature | Notes |
|----|---------|-------|
| S4-02 | Windows support | No hardware — hold |
| F-17 | Multiple Calendar Providers (Outlook, CalDAV) | Too big, future sprint |
| F-09 expanded | Multi-account (stackable instances) | Future sprint |

---

## Scope Risk: macOS

Adding macOS in Sprint 5 is a meaningful scope expansion. Key unknowns:
- macOS OAuth entitlements / sandbox configuration
- always-on-top behavior differences on macOS
- No CI testing on Mac (manual only)

Recommend: **@Morpheus assess macOS complexity** before committing to same sprint as S5-03 through S5-10.

---

## Open Question (1 remaining)

- **Multi-calendar UI**: Calendar selection in Settings panel (gear icon) or separate screen? *(Drew did not specify — defaulting to Settings panel unless told otherwise.)*

---

## Sprint 5 Goal

> **v0.2.0** — Richer UX: multi-calendar, themes, configurable window, click-to-expand, visual polish (color-shift countdown, drop shadow, font +2pt), macOS support.

*Next: @Morpheus *lead arch review sprint5_assessment.md | @Mouse *sm plan sprint 5 board*
