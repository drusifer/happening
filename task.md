# Task Board — Timestrip Hide/Show Sprint (F-31)
**Updated**: 2026-06-11 | **Owner**: @Neo | **QA**: @Trin | **Arch**: @Morpheus | **UX**: @Smith

---

## Sprint Goal
Ship F-31 Timestrip Hide/Show: a ← hide button collapses the strip to a mini countdown+show widget
at top-left; → button or countdown tap restores the full strip. Linux strut and Windows AppBar
released on hide, re-acquired on show. Always starts fully visible.

## Source Artifacts
All sprint artifacts moved to `docs/sprints/F-31/`:
- Product stories: `docs/sprints/F-31/f31_timestrip_hide_stories.md`
- UX Gate 1: `docs/sprints/F-31/f31_gate1_review_2026-06-11.md`
- Architecture: `docs/sprints/F-31/F31_HIDE_SHOW_ARCH_2026-06-11.md`
- UX Gate 2: `docs/sprints/F-31/f31_gate2_review_2026-06-11.md`
- Sprint plan: `docs/sprints/F-31/f31_sprint_plan_2026-06-11.md`
- Previous board (F-30 archive): `docs/sprints/F-31/f30_task_archive_2026-06-11.md`
- Code review: `docs/sprints/F-31/f31_code_review_2026-06-11.md`

## Out of Scope
System tray / full hide. Keyboard shortcut (future sprint). Countdown format changes.
Multi-monitor variants (F-30 handles display selection). The terms "collapse"/"expand" in any
F-31 code identifier or user-facing label.

---

## Phase Board

| Phase | Status | Tasks | Owner |
|-------|--------|-------|-------|
| A — WindowService Hooks | ✅ DONE | F31-A1, F31-A2 | Neo + Trin |
| B — Strip UI | ✅ DONE | F31-B1, F31-B2 | Neo + Trin |
| C — UAT + Docs | 🔄 IN PROGRESS | F31-C1 ✅, F31-C2 🔄, F31-C3 ✅ | Trin + Smith + Oracle |

Dependency: A → B → C (strictly sequential; each gate requires the previous to be green).

---

## Phase A — WindowService Hooks
**Gate**: `make test` green; new tests pass; no UI changes yet

### F31-A1: WindowService public API + protected hooks  ☐ TODO
- **Goal**: Add to `WindowService` (`app/lib/core/window/window_service.dart`):
  - Protected hooks: `onHideStrip()`, `onShowStrip()` (no-ops in base)
  - Public wrappers (called by `_TimelineStripState`):
    - `prepareToHide()` → calls `onHideStrip()`
    - `completeShow()` → calls `onShowStrip()`
    - `resizeToMiniStrip(double fontSizePx)` → `wm.setSize(Size(getMiniWidth(fontSizePx), getCollapsedHeight()))`
    - `resizeToFullStrip()` → `wm.setSize(Size(_screenWidth, getCollapsedHeight()))`
    - `getMiniWidth(double fontSizePx)` → `fontSizePx * 6.0 + 12.0 + 8.0 + 24.0 + 16.0`
  - Note: `wm` and `onHide/onShow` are `@protected`; public wrappers are the only surface
    `_TimelineStripState` touches.
- **Files**: `app/lib/core/window/window_service.dart`
- **Tests**: public wrappers delegate to hooks; `getMiniWidth` formula for 12/14/16px sizes;
  `resizeToMiniStrip` calls `wm.setSize` with correct dimensions

### F31-A2: Linux + Windows hook overrides  ☐ TODO
- **Goal**: Override hooks in platform subclasses:
  - `LinuxWindowService.onHideStrip()` → `_linuxDock.undock()` (only if `windowMode == reserved`)
  - `LinuxWindowService.onShowStrip()` → `_reserveLinuxStrut()`
  - `WindowsWindowService.onHideStrip()` → `_disposeAppBar()` (only if `_enableWindowsAppBar`)
  - `WindowsWindowService.onShowStrip()` → `_registerAppBar()` (only if enabled + mode reserved)
  - macOS inherits base no-op (AC-F31-5-3)
- **Files**: `linux_window_service.dart`, `windows_window_service.dart`
- **Tests**: mock LinuxDockWindowManager — verify undock called on hide, dock on show;
  verify no-op when `windowMode != reserved`; idempotent rapid toggle (AC-F31-4-4)

---

## Phase B — Strip UI
**Gate**: `make test` green; manual: strip hides/shows with animation; countdown live while hidden

### F31-B1: State machine + hide/show methods  ☐ TODO
- **Goal**: Add to `_TimelineStripState`:
  - `bool _isHidden = false`
  - `bool _preHideSentToBack = false`
  - `AnimationController _hideAnim` (300ms, ease-in-out, value=1.0)
  - Add `SingleTickerProviderStateMixin` to `_TimelineStripState`
  - `Future<void> _hideStrip()` — save STB state, restoreToFront if needed,
    call `onHideStrip()`, close settings if open, `setState(_isHidden=true)`,
    `_hideAnim.reverse()`, then `wm.setSize(miniSize)`
  - `Future<void> _showStrip()` — `wm.setSize(fullSize)`, `setState(_isHidden=false, hover/settings reset)`,
    `EC.send(collapsed)`, `_hideAnim.forward()`, call `onShowStrip()`, restore STB if needed
- **Files**: `app/lib/features/timeline/timeline_strip.dart`
- **Tests**: `_isHidden` starts false; hide/show cycle toggles correctly; settings closed on
  hide if open; STB saved + restored; countdown StreamBuilder remains wired while hidden;
  cycle repeatable ≥ 3 times (AC-F31-3-5)
- **Smith Note D**: `_buildCountdownPositioned` returns `Positioned` — extract
  `_buildCountdownContent(...)` as a standalone helper and call it directly in the mini widget
  (the helper already exists at `timeline_strip.dart:768`)

### F31-B2: Hide button + mini widget  ☐ TODO
- **Goal**:
  - Add `_HideButton` widget (← arrow, `minWidth/minHeight: 24`, satisfies AC-F31-1-5)
  - Position at `left: 0` in `_buildLayout` Stack (before existing toolbar at `left: 8`)
  - Add `_buildMiniWidget()` branch in `_buildLayout`: when `_isHidden || _hideAnim.value < 1.0`,
    render mini path — `MouseRegion(cursor: click)` wrapping countdown content + `_ShowButton`
  - Show button (→ arrow) calls `_showStrip()` (AC-F31-3-1)
  - Countdown tap calls `_showStrip()` (AC-F31-3-2)
  - `MouseRegion(cursor: SystemMouseCursors.click)` on whole mini widget (Smith Note A)
  - Pointer stays at `left: 0` during animation (top-left anchor, AC-F31-2-4)
- **Files**: `app/lib/features/timeline/timeline_strip.dart`
- **Tests**: hide button present when not hidden; mini widget present when hidden; show button
  tap triggers show; countdown visible and correct in hidden state; touch target ≥ 24×24
  (Smith Note B)
- **Smith Note E**: Test the hide-end OS window snap on Windows — if double-animation visible,
  move `wm.setSize(miniSize)` before `_hideAnim.reverse()` instead of after
- **Smith Note F**: Validate mini width formula vs "23 h 59 min" — if clipped, add 16px buffer

---

## Phase C — UAT + Docs
**Gate**: Smith approves UAT; Oracle records docs

### F31-C1: Manual UAT  ☐ TODO (Trin)
- **Matrix**:
  - Linux X11: hide → strut released (maximized window expands); show → strut re-acquired
  - Linux Wayland: same
  - Windows: hide → AppBar released; show → AppBar re-acquired
  - macOS: hide/show no strut side effects (AC-F31-5-3)
  - All platforms: countdown live while hidden; ← then → cycle repeatable ≥ 5 times;
    always starts visible on fresh launch (AC-F31-3-6)

### F31-C2: Smith UX pass  ☐ TODO
- Hide button touch target ≥ 24×24px at minimum strip height (AC-F31-1-5 + Note B)
- Pointer cursor on mini widget hover (Note A)
- Animation ≤ 300ms with ease-in-out (AC-F31-1-3)
- Mini widget anchored top-left (AC-F31-2-4)
- Send-to-back state restored after show (D4)
- No "collapse"/"expand" in any user-visible label

### F31-C3: Oracle docs + PRD update  ☐ TODO
- PRD F-31 row → SHIPPED
- LESSONS.md: record z-order save/restore pattern for future hide/show features
- DECISIONS.md: record D2 (Flutter-only animation) rationale

---

## Risks & Watch-list

| Risk | Trigger | Action |
|------|---------|--------|
| Windows snap double-animation | F31-C1 Windows UAT | Move setSize before animation (Smith Note E) |
| Mini width clips countdown text | F31-B2 integration test | Add 16px buffer to getMiniWidth formula |
| wm.setSize not accessible from _TimelineStripState | Phase B implementation | Expose via WindowService.resizeForHide() wrapper |
| STB restore timing (focus steal) | Phase B testing | Ensure restoreToFront+sendToBack don't steal focus |

---

## Parallel / Carry-Over Work

- **F-28 Phase C** (Trin UAT + Morpheus review): still pending; can run parallel with F-31 Phase A
- **F-30 C3/F1/F2**: hardware-blocked on Drew's machine (no action until hardware available)
- **F-30 F3**: Oracle docs — can write post-hardware-verify

---

*Sprint plan by Mouse — 2026-06-11. Morpheus to review plan vs. architecture.*
