# F-31 Sprint Plan — Timestrip Hide/Show

**Date:** 2026-06-11  
**Planner:** Mouse  
**Sprint goal:** Ship F-31 hide/show with strut/AppBar coordination and mini countdown widget.

## Phase Breakdown

### Phase A — WindowService Hooks (2 tasks)
**Owner**: Neo | **QA gate**: Trin | **Arch**: Morpheus
- F31-A1: Base class virtual hooks + getMiniWidth (window_service.dart)
- F31-A2: Linux + Windows overrides (linux/windows_window_service.dart)
- Gate: `make test` green; no UI

### Phase B — Strip UI (2 tasks)
**Owner**: Neo | **QA gate**: Trin
- F31-B1: State machine + _hideStrip/_showStrip (timeline_strip.dart)
  - Add SingleTickerProviderStateMixin, AnimationController, _isHidden, _preHideSentToBack
- F31-B2: Hide button + mini widget (timeline_strip.dart)
  - _HideButton (←), _buildMiniWidget, _ShowButton (→), pointer cursor
- Gate: `make test` green + manual hide/show works

### Phase C — UAT + Docs (3 tasks)
**Owner**: Trin (C1) + Smith (C2) + Oracle (C3)
- F31-C1: Multi-platform UAT matrix
- F31-C2: Smith UX gate
- F31-C3: Oracle docs (PRD, LESSONS, DECISIONS)

## Dependency Graph
A → B → C (strictly sequential)
F-28 Phase C: parallel with F-31 Phase A

## Risks Logged
1. Windows double-animation on hide-end snap (Smith Note E)
2. Mini width formula too narrow for long countdown text (Smith Note F)
3. wm.setSize may not be directly accessible from _TimelineStripState
4. STB restore timing

## Velocity Context
- F-30 reference: Phases A+B completed same-day; C+D+E took 3 days
- F-31 is smaller scope (2 files touched heavily vs 6 for F-30)
- Estimate: Phase A = 1 session; Phase B = 1-2 sessions; Phase C = 1 session

---
*Mouse — 2026-06-11*
