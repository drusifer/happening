# Task Board — Multi-Monitor Support Sprint (F-30)
**Updated**: 2026-05-29 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal
Ship F-30 Multi-Monitor Support: user picks which display the strip lives on, persisted
across reboots, with graceful hot-plug fallback + auto-return and a visible on-strip
indicator when the chosen display is unavailable. Single strip on a single user-chosen
display.

## Source Artifacts
- Product stories: `agents/cypher.docs/f30_multi_monitor_stories.md`
- UX Gate 1: `agents/smith.docs/f30_gate1_review_2026-05-29.md`
- Architecture: `agents/morpheus.docs/F30_MULTIMONITOR_ARCH_2026-05-29.md`
- UX Gate 2: `agents/smith.docs/f30_gate2_review_2026-05-29.md`
- Sprint plan: `agents/mouse.docs/f30_sprint_plan_2026-05-29.md`
- Previous board (F-29 archive): `agents/mouse.docs/f29_task_archive_2026-05-29.md`

## Out of Scope
Multi-strip (one per display), cursor-follow, span across displays, new C++ native code
(Linux strut already monitor-aware; Windows AppBar reuses existing reassert path).

---

## Phase Board

| Phase | Status | Tasks | Owner |
|-------|--------|-------|-------|
| A — DisplayService Foundation | ✅ DONE (2026-05-29) | F30-A1, F30-A2 (probe → C) | Neo + Trin + Morpheus |
| B — Persistence + Fingerprint | ✅ DONE (2026-05-29) | F30-B1, F30-B2 | Neo + Trin + Morpheus |
| C — WindowService Wiring | ☐ TODO | F30-C1, F30-C2, F30-C3 | Neo + Trin (C3) |
| D — Settings UI | ☐ TODO | F30-D1, F30-D2 | Neo |
| E — FallbackIndicator | ☐ TODO | F30-E1, F30-E2 | Neo |
| F — UAT + Docs | ☐ TODO | F30-F1, F30-F2, F30-F3 | Trin + Smith + Oracle |

Dependency graph: A → {B, C, E}; B → D; {C, D, E} → F. C/D/E can run in parallel after A+B.

---

## Phase A — DisplayService Foundation
**Gate**: `make test` green; new tests pass; no UI yet

### F30-A1: DisplayInfo + label fallback chain  ✅ DONE 2026-05-29
- **Goal**: Create `app/lib/core/display/` with `DisplayInfo` value object and
  `labelFor(List<DisplayInfo> all) → String` implementing Smith Note 2's garbage-name chain
  (non-empty + non-generic + unique → OS name; else `"Display N — WxH"`; primary always
  carries ` — primary`).
- **Files**: `app/lib/core/display/display_info.dart`, `app/lib/core/display/display_id.dart`
- **Tests**: all-good names; generic name fallback; duplicate names fallback; null/empty;
  stable index across enumeration-order swap

### F30-A2: DisplayService + state machine  ✅ DONE 2026-05-29 (probe → C2)
- **Goal**: `DisplayService` as `ChangeNotifier`. State machine `CHOSEN_AVAILABLE ↔ IN_FALLBACK`
  (with transient `AUTO_RETURNING`). 250ms debounced subscription to `screen_retriever`
  displayAdded / Removed / metricsChanged.
- **Files**: `app/lib/core/display/display_service.dart`
- **Tests**: init paths; disconnect → fallback; reconnect → auto-return; burst coalescence;
  user choose-display
- **Probe (F30-A2-probe)**: log `screen_retriever` event coverage on each platform. If
  Wayland fires no events → flag for polling fallback in Phase C.

---

## Phase B — Persistence + Fingerprint
**Gate**: `make test` green; persistence survives simulated app restart

### F30-B1: PersistedDisplayChoice in AppSettings  ✅ DONE 2026-05-29
- **Goal**: Add `chosenDisplay: PersistedDisplayChoice?` to `AppSettings`. JSON
  roundtrip via existing settings.json pipeline.
- **Tests**: roundtrip; null roundtrip; backward-compat (missing field loads null)

### F30-B2: Fingerprint match algorithm  ✅ DONE 2026-05-29 (incl. Morpheus Note 1 refactor)
- **Goal**: `PersistedDisplayChoice.matchIn(displays)` implements 3-tier match: exact
  (name+size+offset) → strong (name+size) → weak (name only, logs warning) → null.
- **Tests**: exact; position-changed strong; weak with log; no match

---

## Phase C — WindowService Wiring + moveToDisplay
**Gate**: `make test` green; manual: Settings change → strip moves; Windows AppBar verified

### F30-C1: Strategy.moveToDisplay per platform  ☐ TODO
- **Goal**: Add `moveToDisplay(DisplayInfo)` to `WindowResizeStrategy`. Implement Linux,
  Windows, macOS.
- **Files**: 3 resize_strategy files
- **Linux**: setBounds (strut C++ auto-follows).
- **Windows**: setBounds + reassertAppBar via existing path.
- **macOS**: setBounds.

### F30-C2: WindowService consults DisplayService  ☐ TODO
- **Goal**: Replace `_sr.getPrimaryDisplay()` at `window_service.dart:98, 252` with
  `_displayService.activeDisplay`. Subscribe to DisplayService and call
  `strategy.moveToDisplay()` when activeDisplay changes. Use existing
  `_displayChangeInProgress` race guard.
- **Tests**: fake DisplayService + strategy assert moveToDisplay called correctly.

### F30-C3: Manual Windows AppBar verification  ☐ TODO (BLOCKING)
- **Goal**: Plug in Display 2 on Windows, pick it in Settings, maximize a window on it →
  must stop at strip's bottom edge.
- **Fallback**: if AppBar fails to reseat, switch to ABM_REMOVE + ABM_NEW cycle per arch doc.
- **Owners**: Neo implements; Trin verifies.

---

## Phase D — Settings UI: Display Section
**Gate**: `make test` green; manual: open Settings → see displays → pick → strip moves

### F30-D1: Display section in SettingsPanel  ☐ TODO
- **Goal**: Radio list of `DisplayService.availableDisplays` after Location section.
  Labels via `DisplayInfo.labelFor()`. Radio change → `DisplayService.chooseDisplay(id)`.
- **Tests**: list renders; selection writes through.

### F30-D2: "Currently set: X — unavailable" row  ☐ TODO
- **Goal**: Read-only row at bottom of Display section, visible only when
  `isInFallback == true`. Text per Smith Note 3.
- **Tests**: absent when not in fallback; present + text correct when in fallback.

---

## Phase E — DisplayFallbackIndicator Widget
**Gate**: `make test` green; manual: simulate disconnect → indicator appears; reconnect → fade+slide

### F30-E1: Indicator widget + deep-link tap  ☐ TODO
- **Goal**: `display_fallback_indicator.dart`. `desktop_access_disabled` icon at
  `size = min(14, stripHeight - 8)` (Smith Note A). LEFT of settings gear, ≥8px gap.
  Tooltip "Chosen display unavailable — showing on primary". Tap → opens SettingsPanel and
  auto-scrolls Display section into viewport (Smith Note C).
- **Tests**: invisible when not in fallback; visible + correct size when in fallback; tap
  fires open+scroll callback.

### F30-E2: Auto-return fade + slide animation  ☐ TODO
- **Goal**: On `IN_FALLBACK → AUTO_RETURNING`, indicator fades out 600ms with horizontal
  slide-out toward gear. No animation on entering IN_FALLBACK (only on exit).
- **Tests**: controller fires on correct transition; opacity reaches 0 within 600ms.

---

## Phase F — Multi-Platform UAT + Docs + Release Gate
**Gate**: Smith approves UAT; Oracle records docs; Morpheus code review passes

### F30-F1: Multi-platform manual UAT  ☐ TODO (Trin)
- **Matrix**:
  - Linux X11: pick → strip moves; maximize on chosen → strut OK; unplug → ≤2s fallback;
    replug → auto-return
  - Linux Wayland: same but ≤7s on disconnect (polling fallback per AC-F30-3-1)
  - Windows: same as X11 + AppBar maximize on Display 2
  - macOS: pick → strip moves respecting menu bar; unplug/replug cycle

### F30-F2: Smith UX pass  ☐ TODO
- Indicator legibility at minimum strip height
- Deep-link tap auto-scrolls Display section
- Fade+slide animation reads as "your display came back"

### F30-F3: Oracle docs + PRD update  ☐ TODO
- PRD F-30 row → SHIPPED
- USER_GUIDE.md: Display picker walkthrough + screenshot
- PRD Platform Quirks: Wayland polling fallback exemption recorded

---

## Risks & Watch-list

| Risk | Trigger | Action |
|------|---------|--------|
| `screen_retriever` events missing on Wayland | F30-A2-probe finds no events | 1.5s polling fallback; ≤7s AC covers it |
| Windows AppBar fails on secondary monitor | F30-C3 manual check fails | ABM_REMOVE + ABM_NEW cycle (no C++) |
| Composite fingerprint false-match | UAT edge case | Document; weak-match warning; user re-picks |
| F-28 Phase C overdue when F-30 ships | Sprint timing | F-28 Phase C parallel with F-30 Phase A |

---

## Parallel Work
- **F-28 Phase C**: Trin UAT + Morpheus review still pending; can run in parallel with F-30
  Phase A while Trin awaits F30-C3.

---

*Sprint plan by Mouse — 2026-05-29. Morpheus to review plan vs. architecture.*
