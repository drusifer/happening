# Window State-Machine Refactor — Plan (DRAFT for Morpheus review)

**Author:** Neo (*swe)  **Status:** Draft, awaiting *lead review
**Date:** 2026-06-17
**Related:** LESSONS L-005 (resize normalization), `WindowResizeStrategy.applySize`

---

## 1. Problem

The window's geometry/visibility is established by several overlapping, order-dependent
code paths that each special-case sizing. The active symptom: **on init the timeline strip
comes up as a ~1px black sliver** (window is correctly `3840×55` — confirmed via getSize — so
it is a paint/compositing problem, not a sizing one). It only renders fully after a mouse-over
forces a repaint.

Root cause is structural, not a single bad value:

- Init relies on `onWindowFocus` to trigger the post-show fix-up (`_handleFirstShow`).
  **`onWindowFocus` does not fire reliably** → a 2s **safety-net Timer** fires instead.
- `_handleFirstShow` then **re-reserves the AppBar, repositions (`setPosition(0,0)`), and
  re-resizes** the window ~1.5s AFTER first paint. Shoving the window around post-show with no
  follow-up dirty frame strands the first frame → the sliver until a mouse event composites it.
- Why post-show fix-up exists at all: **Windows ignores size/position set before `ShowWindow`**
  (window creation). So the "correct state" can only be applied after show — today via a
  fragile, focus-dependent, multi-step dance.

This is "the same bug class" we've been chasing: one end-state (the collapsed full strip)
reached by N different, drifting paths.

## 2. Goal & Principles (from product direction)

1. **The app is always in exactly one of three states** — no others exist:
   - `collapsedShown` — full-width strip, collapsed height, visible
   - `expandedShown` — full-width strip, expanded height, visible
   - `hidden` — mini pill, collapsed height (there is no "expanded + hidden")
2. **Geometry is a pure function of state.** Sizing/positioning/reservation = `applyState(s)`.
3. **`applyState` is idempotent.** `setSize`/`applySize` already are; build on that.
4. **No special-case resize logic** scattered across init/show/hide/expand/collapse — those
   become *transitions* that call `applyState` (+ an animation where relevant).
5. **Correct initial state is `collapsedShown`** (`_isHidden == false`).
6. **Delete the hacks:** the `onWindowFocus`/safety-net/`_handleFirstShow` machinery and the
   "force a refresh" AppBar reassert exist only to paper over the races this model removes.

## 3. Target Architecture

### 3.1 State type
```dart
enum StripState { collapsedShown, expandedShown, hidden }
```
Single source of truth replaces the current scattered booleans/enums:
- `_TimelineStripState._isHidden` (bool)
- `ExpansionState {collapsed, expanded}` (ExpansionController)
- implicit "is the window shown" in WindowsWindowService

### 3.2 The one applier
```dart
// WindowService
Future<void> applyState(StripState s) async {
  final size = _sizeFor(s);          // collapsed/expanded/mini × screenWidth/miniWidth
  final origin = _activeDisplay?.workAreaOrigin ?? Offset.zero;
  await _strategy.applySize(size, position: origin);   // idempotent geometry (already centralized)
  await _applyReservation(s);        // AppBar/strut: reserved for *Shown, released for hidden
}
```
`_applyReservation` (platform hook): register-or-reassert for shown states, dispose for hidden.
Windows AppBar and Linux strut both implement this; macOS no-op.

### 3.3 State → effects (the whole contract, in one table)
| State | window size | position | reservation | widget |
|-------|-------------|----------|-------------|--------|
| collapsedShown | 3840 × collapsedH | origin | reserved | `_isHidden=false`, collapsed |
| expandedShown  | 3840 × expandedH | origin | reserved | `_isHidden=false`, expanded |
| hidden         | miniW × collapsedH | origin | released | `_isHidden=true`, mini |

### 3.4 Transitions (animation layered on top, not bespoke geometry)
- init → `applyState(collapsedShown)`
- hover in → `applyState(expandedShown)` (height anim via ExpansionController)
- hover out / collapse → `applyState(collapsedShown)`
- hide → fade (`_hideAnim.reverse`) then `applyState(hidden)`
- show → `applyState(collapsedShown)` then fade-in (`_hideAnim.forward`)

### 3.5 Wiring diagram — resize paths POST-refactor

Every path that establishes geometry collapses onto one state, one applier, one seam:

```
╔════════════════════════════════════════════════════════════════════════════════════╗
║  TRIGGERS                 →  STATE          →  ONE APPLIER          →  GEOMETRY SEAM  ║
╚════════════════════════════════════════════════════════════════════════════════════╝

 init ───────────────┐                            (existing — L-005)
 hover in ───────────┤                          ┌──────────────────────────────────────┐
 hover out ──────────┤   resolve to one         │ WindowResizeStrategy.applySize(size,  │
 collapse ───────────┼──▶ ┌───────────────┐     │                         {position})   │
 show ───────────────┤     │  StripState   │    │   setMinimumSize(Size.zero)           │
 hide (after fade) ──┘     │ ───────────── │    │   setMaximumSize(size)   ← never ∞    │
                           │ collapsedShown│    │   applyGeometry(size, position) ──┐   │
                           │ expandedShown │    │   setMinimumSize(size)            │   │
                           │ hidden        │    └──────────────────────────────────┼───┘
                           └───────┬───────┘                                        │
                                   │                                                ▼
                    WindowService.applyState(state)                 ┌───────────────────────────┐
                                   │                                │ applyGeometry (all plats) │
                  ┌────────────────┴───────────────┐                │  if (position!=null)      │
                  ▼                                 ▼               │     setPosition(position) │
        _sizeFor(state)                   _applyReservation(state)  │  setSize(size)            │
   collapsedShown→3840×collapsedH      *Shown → reserve/reassert    └─────────────┬─────────────┘
   expandedShown →3840×expandedH       hidden → release             window_manager ▼  → Win32/GTK/Cocoa
   hidden        →miniW×collapsedH       (AppBar / strut / no-op)

  ── Transitions (animation only; NOT geometry) ──────────────────────────────────────
   hide  = _hideAnim.reverse()  then  applyState(hidden)
   show  = applyState(collapsedShown)  then  _hideAnim.forward()
   hover = ExpansionController height tween, settling on applyState(expanded/collapsedShown)
```

Contrast with TODAY (what we're deleting): `initialize`→`_reserveCollapsedSpace`, the
`onWindowFocus`/2s-safety-net→`_handleFirstShow` re-reserve+reposition+resize, `reassertAppBar`
"refresh" hack, and the bespoke `resizeToMiniStrip`/`resizeToFullStrip` — all separate paths to
the same end states. Post-refactor there is exactly one: **trigger → StripState → applyState →
applySize**.

## 4. Init flow redesign (the crux — this is what kills the bug)

Replace the focus-driven post-show dance with a deterministic post-show apply:

1. `initialize` → `waitUntilReadyToShow(windowOptions, cb)`; in `cb`: `strategy.initialize`,
   `moveToDisplay`, `setAsFrameless`.
2. `performShow` (actually shows the Win32 window).
3. **Immediately await `applyState(collapsedShown)`** — no focus wait, no Timer. `performShow`
   completing is the "window exists" signal.
4. **`await presentInitialFrame()`** — force ONE OS-level present of the now-final window.

### 4.1 Why an explicit present (not a Flutter repaint)

The build log is decisive: at `10:53:33` the painter rendered the **full strip with
`events=17`** (`size=3840x52`) — a Flutter repaint that happened *after* the last resize — and
the window **still showed only a sliver** until a mouse-over. So:

- A Flutter-side nudge (`setState` / `markNeedsPaint` / request-frame) **will not fix it** — one
  already fired post-resize and did not composite.
- The missing piece is **OS compositing**: Windows is not presenting Flutter's frames for this
  frameless/AppBar window until a window message pumps. Mouse-over is just the WM event you hit.

So the nudge must be an **OS-level invalidate of the HWND**, issued once, as the **last** init
step — after `performShow` AND after `applyState(collapsedShown)` (so no later geometry mutation
re-strands the frame).

### 4.2 `presentInitialFrame()` — the hook

`@protected WindowService.presentInitialFrame()` — base no-op; `WindowsWindowService`
implements it via the FFI we already have (`FindWindow` for `FLUTTER_RUNNER_WIN32_WINDOW`).
Mechanism, cleanest first:

1. `RedrawWindow(hwnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW)` — immediate paint+present, no resize.
2. `InvalidateRect(hwnd, NULL, TRUE)` + `UpdateWindow(hwnd)` — equivalent, two calls.
3. `SetWindowPos(hwnd, …, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER)` — forces a
   non-client recompute + paint without moving/resizing.

Explicitly **not** the "+1px then −1px" nudge: it works but re-introduces the geometry churn we
are deleting. Linux/macOS: no-op unless a compositor quirk shows up.

### 4.3 Sequencing caveat

`waitUntilReadyToShow` reportedly does not await its async callback (current code comment).
Confirm, and ensure steps 3–4 run strictly **after** the window is shown — likely by moving
`applyState` + `presentInitialFrame` out of the ready-to-show callback to right after the
`initialize` future resolves, rather than inside the callback.

### 4.4 Sequence (post-refactor)

```
initialize()
  ├─ waitUntilReadyToShow(opts, cb):  strategy.initialize → moveToDisplay → setAsFrameless
  ├─ performShow()                                   // window becomes visible
  ├─ await applyState(StripState.collapsedShown)     // final geometry + AppBar reservation, ONCE
  └─ await presentInitialFrame()                     // OS-level RedrawWindow → composite the frame
        ✗ no onWindowFocus dependency   ✗ no 2s safety-net   ✗ no _handleFirstShow re-resize
```

## 5. What gets deleted

- `WindowsWindowService._handleFirstShow`, `_firstShowHandled`, `_safetyNet` Timer,
  `afterReadyToShow` safety-net, `onWindowFocus` first-show handling.
- `reassertAppBar` "force a refresh" hack (folded into `_applyReservation`).
- Bespoke `resizeToMiniStrip` / `resizeToFullStrip` semantics → expressed as `applyState`.
- `ExpansionController`/`_isHidden` as *separate* truths → unified `StripState`.
  (ExpansionController may remain as the *animation* driver, not the state owner — TBD.)

## 6. Migration steps (incremental; each step compiles + window tests green)

1. Add `StripState` + `WindowService.applyState` + `_applyReservation` hook (no callers yet).
2. Rewire **init** to `applyState(collapsedShown)` + `presentInitialFrame()`; delete
   `_handleFirstShow`/safety-net/focus machinery. **Validate init sliver is gone on Windows.**
   ← proves the thesis.
3. Migrate hide/show to transitions on `applyState`.
4. Migrate expand/collapse to transitions on `applyState`; retire the reassert hack.
5. Collapse `_isHidden`/`ExpansionState` into `StripState` as the single source of truth.
6. Remove now-dead `resizeToMini/FullStrip` if fully subsumed.

## 7. Risks & Open Questions (for Morpheus)

1. **Ownership:** where does `StripState` live — `_TimelineStripState` (widget), `WindowService`,
   or a new `StripStateController`? Hover/hide are driven from the widget; init from the
   service. Recommend a single owner the widget and service both read. **Lead decision needed.**
2. **First-present nudge (now defined as `presentInitialFrame`, §4.2):** confirm `RedrawWindow`
   is the right mechanism vs `InvalidateRect`+`UpdateWindow` vs `SetWindowPos(SWP_FRAMECHANGED)`.
   Should it run unconditionally, or only when we detect the present didn't land? (Recommend
   unconditional — it's cheap and idempotent; the log shows the quirk is real, not a maybe.)
3. **`waitUntilReadyToShow` not awaiting its callback** — confirm and decide where the init
   `applyState` lands so it runs strictly after show.
4. **AppBar lifecycle in the state model:** register vs reassert vs dispose mapped onto
   `_applyReservation`. Confirm display-change still re-reserves via `applyState`/reservation
   rather than a separate path.
5. **WindowMode (reserved/overlay):** orthogonal to the 3 states? Keep as a separate axis that
   parameterizes `_applyReservation`, or fold in? Recommend keep separate.
6. **Animation vs state:** keep `ExpansionController`/`_hideAnim` as transition animators while
   `StripState` holds truth, or does the controller subsume state? Risk of double sources.

## 8. Testing strategy

- Unit: `applyState(s)` → asserts geometry (via `applySize` bracket, max never `∞`) and the
  correct reservation call per state. Extend `window_resize_strategy_test`/`window_service_test`.
- State-transition table test: every `StripState` maps to the §3.3 row.
- Manual (Windows, the part tests can't see): init shows full strip immediately (no sliver, no
  mouse-over needed); hide/show/expand/collapse cycle; multi-monitor; no 1px.

## 9. Files affected (estimate)

- `core/window/window_service.dart` — `applyState`, `_applyReservation` + `presentInitialFrame`
  hooks, init rewire.
- `core/window/windows_window_service.dart` — delete first-show machinery; AppBar via reservation
  hook; `presentInitialFrame` via FFI `RedrawWindow`.
- `core/window/resize_strategy/*` — unchanged (applySize already the seam).
- `features/timeline/timeline_strip.dart` — drive transitions via `applyState`; unify state.
- `core/window/expansion_controller.dart` — role TBD (animator vs state owner).
- tests: `window_service_test.dart`, `window_resize_strategy_test.dart`.
```
