# Sprint Plan — F-30 Multi-Monitor Support
*Mouse — 2026-05-29*

## Source Artifacts
- Product stories: `agents/cypher.docs/f30_multi_monitor_stories.md`
- UX Gate 1: `agents/smith.docs/f30_gate1_review_2026-05-29.md`
- Architecture: `agents/morpheus.docs/F30_MULTIMONITOR_ARCH_2026-05-29.md`
- UX Gate 2: `agents/smith.docs/f30_gate2_review_2026-05-29.md`

## Sprint Goal
Ship F-30 Multi-Monitor Support: user picks which display the strip lives on, persisted
across reboots, with graceful hot-plug fallback + auto-return and a visible on-strip
indicator when the chosen display is unavailable. Single strip on a single user-chosen
display; no multi-strip; no cursor-follow.

## Out of Scope (Sprint Guard)
- Multiple simultaneous strips (one per display)
- Cursor-follow / active-window-follow auto-switching
- Strip spanning two displays
- New C++ native code (Linux strut already monitor-aware; Windows AppBar reuses existing
  reassert path)

---

## Phase Map

```
A ──► B ──► D ──► F
└───► C ──┘    ▲
└───► E ──────┘
```

- **A** unlocks **B** (persistence), **C** (WindowService wiring), **E** (indicator)
- **B** unlocks **D** (Settings UI needs persistence)
- **C**, **D**, **E** all converge into **F** (UAT)

Neo can pipeline C/D/E in parallel after A+B land; each is independently testable.

---

## Phase A — DisplayService Foundation
**Gate**: `make test` green; new tests pass; no UI yet

### F30-A1: DisplayInfo + label fallback chain
- **Goal**: Create `app/lib/core/display/`:
  - `DisplayInfo` value object: `id`, `osName?`, `size`, `workAreaOrigin`, `workAreaSize`,
    `scaleFactor`, `isPrimary`
  - `DisplayInfo.labelFor(List<DisplayInfo> all) → String` implementing Smith Note 2
    chain: non-empty + non-generic (excludes `Generic PnP Monitor`, `Unknown Display`,
    `Default Monitor`, `Display`) + unique → OS name; else `"Display N — WxH"`. Primary
    always carries ` — primary` suffix. Index is stable sort by `(originX, originY)`.
- **Tests**:
  - All-good OS names → all OS names used, primary suffix correct
  - Generic name → falls back to numeric label
  - Duplicate OS names → both fall back to numeric labels
  - Empty / null name → numeric label
  - Stable index across two displays with swapped enumeration order

### F30-A2: DisplayService + state machine
- **Goal**: `app/lib/core/display/display_service.dart` as `ChangeNotifier`:
  - `activeDisplay`, `availableDisplays`, `isInFallback`, `persistedChoiceId`
  - `initialize()` hydrates from `screen_retriever` + `AppSettings`
  - `chooseDisplay(DisplayId)` updates state and notifies
  - Subscribes to `screen_retriever` displayAdded / Removed / metricsChanged
  - 250ms trailing debounce on event coalescence
  - State machine: `CHOSEN_AVAILABLE` ↔ `IN_FALLBACK` (with transient `AUTO_RETURNING`)
- **Tests**:
  - Init with persisted choice that matches → CHOSEN_AVAILABLE
  - Init with persisted choice absent → IN_FALLBACK
  - Disconnect chosen → IN_FALLBACK + notify
  - Reconnect chosen → AUTO_RETURNING → CHOSEN_AVAILABLE + notify
  - Burst of 5 events within 250ms → single state transition
  - User picks new display → IN_FALLBACK cleared if matches
- **Risk probe (F30-A2-probe)**: log `screen_retriever` event coverage on each platform
  during dev; if Wayland never fires → switch to polling per Morpheus's mitigation. Document
  result before Phase C.

---

## Phase B — Persistence + Fingerprint
**Gate**: `make test` green; persistence survives simulated app restart

### F30-B1: PersistedDisplayChoice + AppSettings field
- **Goal**: Add `chosenDisplay: PersistedDisplayChoice?` to `AppSettings`. Serialize via
  existing settings.json pipeline. `null` = default (primary).
- **Tests**: roundtrip JSON; null roundtrip; backward-compat: settings.json without the
  field loads to null.

### F30-B2: Fingerprint match algorithm
- **Goal**: `PersistedDisplayChoice.matchIn(List<DisplayInfo>) → DisplayInfo?` implementing
  the 3-tier match (exact / strong / weak per arch doc Identity & Persistence section).
  Logs a warning on weak match.
- **Tests**:
  - Exact match found
  - Position changed → strong match wins
  - Name only → weak match + warning
  - No match → null

---

## Phase C — WindowService Wiring + moveToDisplay
**Gate**: `make test` green; manual smoke: change Settings selection → strip moves displays

### F30-C1: Strategy.moveToDisplay per platform
- **Goal**: Add `moveToDisplay(DisplayInfo d)` to `WindowResizeStrategy`. Implement in
  `LinuxResizeStrategy`, `WindowsResizeStrategy`, `MacosResizeStrategy`.
- **Linux**: `setBounds(workAreaOrigin, workAreaSize.width × collapsedHeight)`; strut C++
  auto-follows via existing `gdk_display_get_monitor_at_window`.
- **Windows**: `setBounds(...)` + call existing `onDisplayChangedExtra` reassert path;
  verify AppBar `rcTop` reseats to chosen display's coordinates.
- **macOS**: `setBounds(workAreaOrigin, workAreaSize.width × collapsedHeight)`.

### F30-C2: WindowService consults DisplayService
- **Goal**: `WindowService` takes `DisplayService` as a constructor dep. Replace
  `_sr.getPrimaryDisplay()` calls at `window_service.dart:98` and `:252` with
  `_displayService.activeDisplay`. Subscribe to `DisplayService` notifications and call
  `strategy.moveToDisplay()` when activeDisplay changes. Use existing
  `_displayChangeInProgress` race guard.
- **Tests**: fake `DisplayService` + fake strategy: assert moveToDisplay called with chosen
  display; assert primary used when no chosen.

### F30-C3: Manual Windows AppBar verification (BLOCKING)
- **Goal**: Build Windows, plug in second monitor, choose Display 2 in Settings, maximize a
  window on Display 2, verify it stops at the strip's bottom edge (not display top).
- **Fallback path**: if AppBar doesn't reseat via `onDisplayChangedExtra`, switch to
  ABM_REMOVE + ABM_NEW unregister/re-register cycle per arch doc.
- **Owner**: Neo + Trin verification. Morpheus consults on the fallback path if needed.

---

## Phase D — Settings UI: Display Section
**Gate**: `make test` green; manual: open Settings → see displays listed → pick → strip moves

### F30-D1: Display section in SettingsPanel
- **Goal**: New section after Location (F-29). Radio list of `DisplayService.availableDisplays`
  with labels from `DisplayInfo.labelFor()`. Selected radio = `DisplayService.persistedChoiceId`
  match. Radio change → `DisplayService.chooseDisplay(id)` immediately.
- **Tests**: widget tests with fake DisplayService — list renders; selection writes through.

### F30-D2: "Currently set: X — unavailable" row
- **Goal**: Read-only informational row at the bottom of the Display section, visible only
  when `DisplayService.isInFallback`. Text: `"Currently set: {labelOfPersistedChoice} —
  unavailable. Showing on primary until it reconnects."`
- **Tests**: row absent when not in fallback; row present + text correct when in fallback.

---

## Phase E — DisplayFallbackIndicator Widget
**Gate**: `make test` green; manual: simulate disconnect → indicator appears; reconnect →
fade+slide-out animation completes

### F30-E1: Indicator widget + deep-link tap
- **Goal**: `app/lib/features/timeline/display_fallback_indicator.dart`. Listens to
  `DisplayService`. Renders `desktop_access_disabled` icon at
  `size = min(14, stripHeight - 8)` per Smith Gate 2 Note A. Placed immediately LEFT of
  settings gear with ≥8px gap (matches F-29 gear-adjacency rule). Tooltip: "Chosen display
  unavailable — showing on primary." Tap → opens SettingsPanel **and auto-scrolls Display
  section into the visible viewport** per Smith Gate 2 Note C.
- **Tests**: invisible when not in fallback; visible + correct size when in fallback; tap
  fires the open+scroll callback.

### F30-E2: Auto-return fade + slide animation
- **Goal**: When state transitions `IN_FALLBACK → AUTO_RETURNING`, indicator fades out over
  600ms with horizontal slide-out toward the gear. Animation runs once per auto-return.
- **Tests**: animation controller fires on transition; opacity reaches 0 within 600ms;
  no animation when entering IN_FALLBACK (only on exit).

---

## Phase F — Multi-Platform UAT + Docs + Release Gate
**Gate**: Smith approves UAT; Oracle records docs; Morpheus code review passes

### F30-F1: Multi-platform manual UAT (Trin)
- **Goal**: Test matrix:
  - Linux X11: pick Display 2 → strip moves; maximize window on Display 2 → stops at strip;
    unplug Display 2 → fallback within 2s; replug → auto-return.
  - Linux Wayland: pick Display 2 → strip moves; unplug → fallback within 7s (polling); replug → auto-return.
  - Windows: same as Linux X11 + AppBar maximize check on Display 2.
  - macOS: pick Display 2 → strip moves; respect menu bar work area; unplug/replug cycle.
- **Output**: UAT report with pass/fail per matrix cell; defects filed via `*user bug`.

### F30-F2: Smith UX pass
- **Goal**: Smith runs the app per Smith Gate 2 promised follow-ups:
  - Verify indicator legibility at minimum strip height
  - Verify deep-link tap auto-scrolls Display section
  - Verify fade+slide animation reads as "your display came back"
- **Output**: `*user approve` or non-blocking notes for post-ship polish.

### F30-F3: Oracle docs + PRD update
- **Goal**: Update `docs/PRD.md` F-30 row to mark SHIPPED. Update `USER_GUIDE.md` with
  Display picker walkthrough + screenshot. Record Wayland polling fallback exemption in
  PRD's "Platform Quirks" / appendix.
- **Output**: docs PR ready for review.

---

## Risks & Watch-list

| Risk | Trigger | Action |
|------|---------|--------|
| `screen_retriever` events absent on Wayland | F30-A2-probe finds zero events | Switch to 1.5s polling per Morpheus fallback; ≤7s AC already covers it |
| Windows AppBar fails to reseat on secondary monitor | F30-C3 manual check fails | Switch to ABM_REMOVE+ABM_NEW path; no new C++ |
| Composite fingerprint false-match (two identical monitors swapped) | UAT edge case | Document; weak-match warning logged; user can re-pick |
| Indicator too small at minimum strip height | Smith F30-F2 review | Visual-diff test added; clamp logic adjusts |
| F-28 Phase C still outstanding when F-30 ships | Sprint timing | Run F-28 Phase C in parallel with F-30 Phase A (Trin has bandwidth before C3) |

---

## Estimate

| Phase | Tasks | Effort |
|-------|-------|--------|
| A | 2 | S |
| B | 2 | S |
| C | 3 | M (manual Windows verify) |
| D | 2 | S |
| E | 2 | S |
| F | 3 | M (multi-platform UAT) |
| **Total** | **14 tasks** | **~2 weeks of focused work** |

Comparable to F-29 (5 phases, ~328 tests). F-30 likely adds ~30-40 tests.

---

*Sprint plan by Mouse — 2026-05-29. Awaiting Morpheus review of plan vs. architecture.*
