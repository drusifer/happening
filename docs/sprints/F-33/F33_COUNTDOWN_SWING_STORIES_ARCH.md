# F-33 Countdown Swing — Stories & Architecture (Tier 2 fast-track)

**Created**: 2026-10-02 | **Authors**: @Cypher & @Morpheus | **Gate**: @Smith (single combined gate)

---

## 0. Request (Drew, verbatim intent)
> In the last ~10 seconds before a meeting starts, when the countdown timer goes
> big and starts the shaking color change, also make it swing back and forth
> across the whole timeline strip to really catch my attention. Travel
> horizontally through the full strip width while in the big shaking phase, then
> stop once the meeting starts. Fast, but stop and return to its regular
> position if I mouse over the strip.

### Current behaviour (code facts, `timeline_strip.dart`)
| Effect | Threshold today | Driver |
|---|---|---|
| Scale ramp 1×→3× | 120s → 30s, holds 3× ≤30s | `_buildCountdownContent` |
| Horizontal shake ±2px | ≤60s | `_flashNotifier` (200ms `Timer.periodic`) |
| Rainbow colour flash | <2 min | `_resolveCountdownColor` |
| Position | Pinned beside the now-indicator (`_buildCountdownPositioned`) | `Positioned(left/right)` |

So at T≤10s every existing effect is already active; F-33 adds the swing on top.

---

## 1. Stories & Acceptance Criteria

### F33-1: Swing across the strip in the final 10 seconds
*As a user who loses track of time, I want the countdown to sweep across the
whole strip in the final seconds so it is impossible to miss.*
- **AC-1** Swing is active iff ALL hold: `0 < remaining ≤ 10s`; the countdown
  target is a **meeting start** (same `isTargetingMeetingStart` used by F-32
  audio — not an end-of-meeting countdown); strip is shown (not F-31 hidden/mini);
  `enableAnimations` is true; pointer is not over the window (F33-2).
- **AC-2** While active, the countdown travels horizontally from the strip's
  left edge to its right edge and back, continuously. The 3× scaled countdown
  stays fully inside the strip at both extremes (no clipping off-screen).
- **AC-3** Fast: one edge-to-edge sweep takes **700ms** (1.4s round trip), eased
  (sine in/out) so it visibly "turns around" at each edge. Smooth (vsync-driven),
  not stepped at the 200ms flash cadence.
- **AC-4** Existing scale (3×), shake, and colour flash continue unchanged
  during the swing.
- **AC-5** At `remaining == 0` (meeting starts) the swing stops and the
  countdown returns to its regular now-indicator position in the same frame.
- **AC-6** Tap-to-mute (F-32) still works on the countdown wherever it is.

### F33-2: Mouse-over cancels the swing
*As a user reaching for the strip, I don't want to chase a moving target.*
- **AC-7** When the pointer enters the window (collapsed strip or expanded card
  area) the swing stops and the countdown snaps to its regular position
  immediately (same frame as the hover event).
- **AC-8** *(Default — see OQ-F33-1)* When the pointer leaves and AC-1 still
  holds, the swing resumes.

### F33-3: Respect OS reduce-motion *(added at Smith gate)*
- **AC-9** If the OS requests reduced motion
  (`MediaQuery.disableAnimationsOf(context)`), the swing never starts. The
  existing scale/shake/colour effects are unchanged (out of scope). Where the
  platform does not report the flag, this is a no-op.

### Out of scope
- F-31 mini/hidden pill (no room to swing; unchanged).
- New in-app settings toggle (OS reduce-motion covers it; see OQ-F33-3).

### Open questions (defaults chosen so Neo is unblocked)
| ID | Question | Default |
|---|---|---|
| OQ-F33-1 | Resume swinging after the mouse leaves (before T=0)? | **Yes** |
| OQ-F33-2 | Snap back on hover, or animate back? | **Snap** (immediate) |
| OQ-F33-3 | Separate in-app "reduce motion" setting? | **No** — honour OS flag (AC-9); `enableAnimations` is test-only |
| OQ-F33-4 | Should tap-to-mute also stop the swing? | **No** — mute is audio-only |
| OQ-F33-5 | Threshold 10s vs tie to the 30s "big" phase? | **10s** (Drew's number) |

---

## 2. Architecture (Morpheus)

### 2.1 Pure logic — `lib/features/timeline/countdown_swing.dart` (new)
```dart
/// Final-seconds attention swing (F-33).
abstract final class CountdownSwing {
  static const threshold = Duration(seconds: 10);
  static const sweep = Duration(milliseconds: 700);

  /// Gate for AC-1 / AC-7.
  static bool isActive({
    required Duration remaining,
    required bool targetsMeetingStart,
    required bool isHidden,
    required bool animationsEnabled,
    required bool pointerInside,
    required bool reduceMotion, // AC-9
  });

  /// Maps controller value t∈[0,1] → horizontal Alignment x∈[-1,1] (eased).
  static double alignmentX(double t) => -math.cos(t * math.pi);
}
```
Pure + unit-testable, no widget dependencies.

### 2.2 Animation driver — `_TimelineStripState`
- Change mixin `SingleTickerProviderStateMixin` → `TickerProviderStateMixin`
  (second controller alongside `_hideAnim`).
- `_swingAnim = AnimationController(vsync: this, duration: CountdownSwing.sweep)`.
- `_updateSwing(bool active)`: if active and not animating →
  `_swingAnim.repeat(reverse: true)`; if inactive and animating → `stop()` +
  `value = 0`. Called from the countdown tick builder (alongside
  `_updateAnimationTimer`) and from `_handleMouse` enter/exit so AC-7 is
  same-frame, not next-tick.
- `pointerInside`: new `_isPointerInWindow` flag set true on `onEnter`/`onHover`,
  false on `onExit` (the existing `_isHoveringStrip` is only the collapsed band,
  so it misses the expanded card area required by AC-7). Set it at the TOP of
  `_handleMouse`, before the `isSentToBack` / `layout == null` early returns.
- Dispose `_swingAnim` in `dispose()`.
- **Build-phase rule (Morpheus review):** the countdown tick builder runs during
  build, and `AnimationController.stop()/value=` notifies listeners
  synchronously → `setState() called during build` via `AnimatedBuilder`.
  So from the builder, *decide* swing vs regular layout purely from
  `CountdownSwing.isActive(...)` (visual snap is therefore same-frame), and
  defer the controller start/stop with `addPostFrameCallback`. Direct calls are
  fine from `_handleMouse` (event phase, not build).

### 2.3 Layout — `_buildCountdownPositioned`
- **Inactive**: unchanged (`Positioned` left/right pinned to now-indicator).
- **Active**: `Positioned(left: 0, right: 0, top: 0, height: collapsedH)` →
  `RepaintBoundary` → `AnimatedBuilder(_swingAnim)` → `Align(alignment:
  Alignment(x, 0))` → existing tap/mouse/`_buildCountdownContent`, with
  `_CountdownContentSpec.alignment = Alignment(x, 0)`.
- Passing the same alignment to `Transform.scale` makes the 3× scale grow
  *inward* from whichever edge it is near, so the scaled glyph never leaves the
  strip (AC-2) without measuring widget width.
- `RepaintBoundary` keeps the 60fps repaint to the countdown layer only; the
  `TimelinePainter` does not repaint. No OS window resize is involved, so the
  F-32-era Impeller resize crash path is not touched.

### 2.4 Test strategy
- **Unit** (`test/features/timeline/countdown_swing_test.dart`): `isActive`
  truth table (each AC-1 condition flips it off; boundaries 10s on / 11s off /
  0s off); `alignmentX(0) == -1`, `alignmentX(0.5) ≈ 0`, `alignmentX(1) == 1`.
- **Widget** (`timeline_strip_test.dart`, `enableAnimations: true`, fake clock):
  - T=8s to a meeting start → countdown `Align` x changes across pumps and
    reaches both |x|≈1.
  - T=15s → regular `Positioned` (no swing `Align`).
  - T=8s but countdown to meeting **end** → no swing.
  - Pointer enters → regular position same pump; exits → swing resumes.
  - T reaches 0 → regular position.
  - `MediaQuery(disableAnimations: true)` → no swing (AC-9).
- Goldens use `enableAnimations: false` → unaffected.

### 2.5 Risk
| Risk | Mitigation |
|---|---|
| 60fps repaint cost on 5120px-wide strip | `RepaintBoundary`; only 10s per meeting |
| Hit-testing a moving target | AC-7 stops it as soon as the pointer enters |
| Ticker leak | Stop in `_updateSwing(false)`, dispose in `dispose()`; widget test asserts no pending tickers |
