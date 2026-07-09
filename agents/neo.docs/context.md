# Neo Context — 2026-06-17 (see 2026-07-09 UPDATE for most current)

## 2026-07-09 UPDATE — sync_version.py version-sync bug (see current_task.md for full detail)
- Lesson: `sync_version.py`'s regexes (`update_metadata`, `update_pubspec`) used `[\d\.]+`, which
  excludes `+` — so once a target file's version string carries a Flutter build suffix (`0.5.3+1`),
  the regex either fails to match at all (silent no-op, no error) or matches only the numeric prefix
  and leaves the old suffix stranded. `re.subn`'s count return was already there to detect this but
  nothing checked/surfaced it upstream (`sync_all`/`main` ignore the bool). Fixed both patterns to
  `[\d.]+(?:\+\S+)?`.
- No Python test runner existed for `agents/tools/`; added `make test-tools` (stdlib `unittest
  discover`) as the first one — future Python-tool tests go in `agents/tools/test_*.py`.
- General takeaway: this class of bug (silent no-op on regex non-match) is easy to miss because nothing
  crashes — `main()`'s per-step `[OK] Updated ...` print lines are the only signal, and they're easy not
  to check. Worth grep-ing `sync_version.py` output whenever a version bump doesn't show up somewhere.

## 2026-07-01 UPDATE — macOS ASWebAuth impl (parallel track, see current_task.md for full detail)
- oauth_redirect_handler.dart architecture: `OAuthRedirectHandler.start()` returns the redirect URI;
  `authenticate(Uri authUrl)` now owns BOTH the browser-launch and the callback-wait (was split across
  auth_service.dart's launchUrl call + a separate waitForCallback()). Each platform impl decides how:
  macOS's `_ASWebAuthRedirectHandler` delegates the whole thing to `FlutterWebAuth2.authenticate()`;
  Windows/Linux's `_LoopbackRedirectHandler` explicitly calls `launchUrl` then awaits its HttpServer.
- Native plugin error codes aren't in any README — had to read `FlutterWebAuth2Plugin.swift` in the pub
  cache directly to learn cancel surfaces as `PlatformException(code: 'CANCELED')`. Worth remembering:
  for this plugin, source > docs.
- `flutter_web_auth_2`'s platform-interface (`FlutterWebAuth2Platform.instance`, settable) is the seam
  for testing without a real system sheet — see oauth_redirect_handler_test.dart's `_FakeWebAuthPlatform`.

## 2026-06-19 UPDATE — refactor implemented + Windows-verified; now CONVERGING entrypoints
The 3-state plan below is IMPLEMENTED. StripState + applyState + StripController + AsyncGate + the
WindowsAppBar seam all exist and are green. Init bug chain FIXED on real Windows. Current work:
converging ALL window entrypoints onto applyState (only init used it). See
`docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md` and `next_steps.md` for the live plan + resume.

Durable findings this round:
- **The init sliver was present-timing**, not position: presentInitialFrame ran BEFORE Flutter's
  first frame (initialize() runs before runApp). Fix: defer present to addPostFrameCallback + a 1px
  SHRINK-settle (grow-past-band makes Windows relocate the AppBar window).
- **Below-strut on refresh/show = async OS relocation** to (0,73) ~150ms after we set (0,0), on
  ABM_REMOVE→ABM_NEW cycles. Outside AsyncGate. Confirmed via +Nms probes. Drew's ABM_REMOVE instinct.
- **applyState now reserves FIRST then positions** (ABM_SETPOS can move the window; position after).
- **Band height uses CEIL(h*dpr)** so DPI rounding can't leave the window taller than its band.
- **Testing method (L-006)**: model the OS reaction in a fake (FakeWin32Desktop), assert resulting
  state, and PROVE the test fails on the bug. Mocks that only record calls are worthless for OS bugs.
- **Keep all GEO/probe logging** (Drew directive). chat MSG ≤256 (draft ≤230, count first).

## Window subsystem (2026-06-17 — historical): resize normalization DONE; init paint bug diagnosed; refactor planned.

### The resize seam (DONE — LESSONS L-005)
- `WindowResizeStrategy.applySize(Size, {Offset? position})` is THE one resize primitive.
  Bracket: setMinimumSize(Size.zero) → setMaximumSize(size) → applyGeometry(size,position) →
  setMinimumSize(size). **Never setMaximumSize(Size.infinite)** — it leaves a garbage native
  max-track and Win32 truncates the window to OS-min (~136×39).
- `applyGeometry` = setPosition + setSize on ALL platforms. NOT setBounds: setBounds flakes on
  Windows first show (lands ~1px, setMin can't force-grow it back). setSize + the max-cap is reliable.
- Routed through applySize: expand, collapse, resizeToMiniStrip, resizeToFullStrip,
  WindowsWindowService._reserveCollapsedSpace. Deleted: _resizeViaBounds + the base hand-rolled brackets.
- 54 window tests green; window_resize_strategy_test asserts max never ∞.

### Init "1px sliver" bug — it's PAINT/COMPOSITING, not geometry
- Proven via getSize: OS window is Size(3840, 55) at all init checkpoints.
- The window is shoved around AFTER first paint: onWindowFocus never fires → 2s safety-net →
  _handleFirstShow re-reserves/repositions/re-resizes ~1.5s post-paint → strands the frame.
- Windows doesn't composite Flutter's frames for this frameless/AppBar window until a WM event
  (mouse-over). A Flutter repaint already fired post-resize (events=17) and did NOT present →
  the fix must be an OS-level present (RedrawWindow), not setState.

### The plan (docs/WINDOW_STATE_REFACTOR_PLAN.md) — awaiting Morpheus *lead review
- 3 states only: collapsedShown / expandedShown / hidden. Geometry = pure fn of state.
- applyState(state) idempotent applier = _sizeFor(state) → applySize + _applyReservation(state).
- presentInitialFrame() hook: Windows FFI RedrawWindow, run once as the LAST init step.
- Deletes: onWindowFocus first-show, 2s safety-net, _handleFirstShow, reassertAppBar "refresh" hack,
  bespoke resizeToMini/Full.
- Incremental migration; init first (step 2) to prove the thesis.

### Architecture map (window subsystem)
- WindowService (base): public API resizeToMini/FullStrip, performResize/_doExpand/_doCollapse,
  initialize (WindowOptions + waitUntilReadyToShow + beforeShow + performShow + afterReadyToShow),
  prepareToHide/completeShow → onHideStrip/onShowStrip. Holds _strategy (now @protected `strategy` getter).
- WindowsWindowService: AppBar via SHAppBarMessage FFI (_registerAppBar/_disposeAppBar/
  _reserveCollapsedSpace/reassertAppBar), _handleFirstShow + safety-net + onWindowFocus (TO BE DELETED).
- WindowResizeStrategy: applySize/applyGeometry + expand/collapse delegators; resizable getter
  (Linux=true per L-001). Thin platform subclasses.
- TimelineStrip (_TimelineStripState): _hideStrip/_showStrip; _isHidden; _hideAnim (value:1.0=shown);
  ExpansionController drives height; build returns _buildMiniWidget when _isHidden||_hideAnim.value<1.

### Working-style / tooling
- User builds & tries candidate fixes BEFORE Neo runs full suite (token cost). App logs INFO+ to
  build/build.out (HOME unset on Windows → ignore $HOME path). make chat 256-char limit → docs/.
- wm.getDevicePixelRatio() is SYNC (no await). dpr=1.0 on this 4K monitor (no DPR mismatch).
- .vscode/launch.json exists (Windows debug/profile; cwd=app, program=lib/main.dart).

### Lessons: L-001 (GTK setSize), L-005 (Windows setMax(∞) truncates; setBounds first-show flake). docs/LESSONS.md.
