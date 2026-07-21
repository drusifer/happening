# Neo Current Task — 2026-07-21

## STATUS: Makefile lint scope after integration harness deletion — FIXED
- Shared analyzer source-root selection now always includes `lib test` and
  conditionally adds `integration_test` only when its directory exists.
- Applied to `analyze`, `lint-style`, and `win-test` analyzer entry points.
- `make lint-style V=-vv` passed with no analyzer issues.
- Handed to Trin for the full quality gate; no Neo work remains.
- Summary: `Makefile_Conditional_Analyze_Scope_Summary_2026-07-21T17-24.md`.

## STATUS: lunar-day sunset transition regression — FIXED, handed to Trin
- Trin supplied an independently specified 12-row dusk/dawn matrix, red in 3
  dusk landing-color cases.
- Production fix resolves brightness independently at segment start and end;
  expected matrix values were not changed.
- Focused astronomical background test passed 26/26 after `make format`.
- Full QA remains with Trin. No Neo implementation work remains.
- Summary: `Lunar_Transition_Merge_Fix_Summary_2026-07-21T17-10.md`.

# Neo Current Task — 2026-07-09 (historical; 07-08 and 07-01 sections below)

## STATUS (2026-07-09 #2): hide-after-display-reapply strand bug — FIXED, tests added. DONE.
- Repro (Drew): open Settings, re-select the Display setting (even the SAME display), press Hide
  → strip hides but lands below where its strut would be.
- Root cause: `WindowService.applyState`'s origin fallback was `reservedOrigin ??
  _activeDisplay?.workAreaOrigin ?? Offset.zero`. Our OWN Windows AppBar reservation shrinks the
  OS-reported work area WHILE it is registered (Windows recalculates `rcWork` to exclude a
  registered AppBar band). Re-selecting a display in Settings calls
  `DisplayService.setPersistedChoice` → `_refresh()`, which re-probes displays LIVE — since the
  reservation is active at that moment, the freshly-probed `DisplayInfo.workAreaOrigin` is already
  shifted down by the band height. `DisplayInfo.==` includes `workAreaOrigin`, so this reads as a
  genuine "display changed" event even though it's the SAME monitor — purely a side effect of our
  own reservation. `WindowService._onDisplayChangedInner` then caches this shrunk `DisplayInfo` as
  `_activeDisplay`. The SHOWN re-apply right after stays correct (Windows' `applyReservation`
  returns an origin from the AppBar's own `rcTop`, immune to work-area shrinkage) — but later,
  pressing Hide → `applyState(hidden)` → `applyReservation` disposes the AppBar and returns null →
  origin falls back to the now-contaminated `_activeDisplay.workAreaOrigin` → mini pill lands at
  the shrunk work-area Y instead of the strut top.
- Test-first: added a regression test in `windows_window_service_test.dart` (`display-reset then
  hide (regression)` group) using a `_FixedResolver` (DisplayChoiceResolver) to simulate
  DisplayService resolving to a `DisplayInfo` whose `workAreaOrigin` is already shrunk by our own
  reservation, then asserting `hideStrip()` still lands at `Offset.zero`. Confirmed RED first
  (actual `Offset(0, 73)`).
- **First pass (reverted, Drew flagged it as a special case, not a fix)**: cached the last
  successful `applyReservation` origin on `WindowService` and fell back to it before the work
  area. Worked, but was a patch: added mutable state with an implicit "must have been shown before
  hidden" invariant nothing enforces, and didn't even cover `WindowMode.overlay` starting cold
  (cache never warms if the app never reserves). Reverted `window_service.dart` back to its
  original `reservedOrigin ?? _activeDisplay?.workAreaOrigin ?? Offset.zero` — untouched.
- **Actual fix**: `WindowsWindowService.applyReservation`'s hidden/unreserved branch now returns
  `Offset(workAreaOrigin.dx, 0)` directly instead of `null`. Reasoning: `workAreaOrigin.dy` is
  definitionally "space not reserved by us" — using it to place OUR OWN window is circular the
  moment our own reservation is what shrank it, on Windows specifically, in EVERY windowMode
  (reserved and overlay alike). `workAreaOrigin.dx` stays safe to use (a full-width top strut never
  shrinks the work area horizontally, so it's genuine multi-monitor X placement, not
  self-contamination). `applyState`'s `?? _activeDisplay?.workAreaOrigin` fallback is now
  effectively dead code on Windows (reservedOrigin is never null there anymore) and stays exactly
  as-is for macOS/Linux, which never call any of this Windows logic — no shared-code blast radius,
  no cache, no new field, no invariant to maintain.
- Verified GREEN: new test passes; `make win-test FILE=test/core/window/` — analyze clean, 83/83
  window tests green; full `make test` — 493 green, only the 2 pre-existing golden failures
  (documented since 2026-06-22/2026-07-01, unrelated) remain.
- Files: `app/lib/core/window/windows_window_service.dart` (`applyReservation`'s
  hidden/unreserved-branch return value only — `window_service.dart` ended up untouched),
  `app/test/core/window/windows_window_service_test.dart` (`_FixedResolver` + new regression
  test group).
- **Related gap found, NOT fixed (out of scope for this repro, flagged for follow-up)**:
  `WindowService._reapplyCurrentState()` derives the state to reapply purely from the `_isExpanded`
  bool (`_isExpanded ? expandedShown : collapsedShown`) — it has no way to represent `hidden`.
  `StripState.hidden.isExpanded == false`, same as `collapsedShown`. So if a display or font-size
  change fires while the strip is legitimately HIDDEN, `_reapplyCurrentState` will force it back to
  `collapsedShown` (un-hide it) — WindowService has no visibility into StripController's actual
  `StripState.hidden`. Did not reproduce in Drew's repro (strip was shown, not hidden, when the
  display reapply fired), so left alone as scope discipline — but it's a real latent bug in the
  same subsystem. Next step if picked up: give `WindowService` a way to know the strip is
  hidden (e.g. have `StripController` pass/track it) so `_reapplyCurrentState` can no-op instead of
  un-hiding.

## STATUS (2026-07-09): sync_version.py build-suffix bug — FIXED, tests added. DONE.
- Bug: settings panel ("SETTINGS v. $appVersion") stuck showing '0.5.3+1' after version.txt was
  bumped to 0.5.4 and `make sync-version`/`make set-version` was run. Root cause:
  `sync_version.py`'s `update_metadata()` regex `[\d\.]+` doesn't include `+`, so once
  `app_metadata.dart`'s `appVersion` constant carries a Flutter build suffix (e.g. `'0.5.3+1'`),
  the regex never matches again — `re.subn` returns count=0, function returns False, file is
  silently never updated (no error surfaced). Same flaw existed in `update_pubspec()`'s version
  regex, but there it partially matched (stopped before `+`) and left a stray `+N` suffix
  (`0.5.3+2` → `0.5.4+2`) instead of failing outright — same root cause, different symptom.
- Test-first: added `agents/tools/test_sync_version.py` (stdlib unittest, monkeypatches
  `sv.METADATA_FILE`/`sv.PUBSPEC_FILE` to a tempfile so it never touches real project files).
  Added a `test-tools` Makefile target (`python -m unittest discover -s agents/tools`) since no
  Python test runner existed yet for `agents/tools/`. Confirmed RED (`make test-tools`) before fixing.
- Fix: both regexes changed from `[\d\.]+` to `[\d.]+(?:\+\S+)?` so an existing `+build` suffix is
  consumed and replaced, not left stranded or blocking the match entirely.
- Verified GREEN: `make test-tools` (3/3 pass). Ran `make sync-version` for real — `app_metadata.dart`
  now correctly shows `appVersion = '0.5.4'`. `make test FILE=test/features/timeline/settings_panel_test.dart`
  — 25/25 green (that test asserts `$appVersion` interpolated, not hardcoded, so it was never
  failing — the bug was invisible to existing Dart tests; only a Python-level regex issue).
- Files: `agents/tools/sync_version.py`, `agents/tools/test_sync_version.py` (new), `Makefile`
  (new `test-tools` target + `.PHONY`/`MKF_TARGETS` entries), `app/lib/core/app_metadata.dart`
  (data fix, 0.5.3+1 → 0.5.4), `app/pubspec.yaml`/`app/assets/version.txt` (already at 0.5.4,
  untouched by this fix — msix_version re-synced identically).
- NOT investigated: whether the same `[\d\.]+`-style pattern appears in `update_snapcraft()` —
  untested, lower risk (Linux-only, optional file, no reported symptom). Flag if it recurs there.

## FOLLOW-UP (2026-07-09 #3): msix_version formula was also broken — FIXED
- `update_pubspec`'s old msix formula (`f"1.0.{parts[0]}.{parts[1]}{parts[2]}"`) was nonsensical —
  string-concatenated minor+patch into one field (`0.5.4` → `1.0.0.54`) and, since it split on `.`
  only, a `+build` suffix leaked into the last field verbatim (`0.5.4+9` → `1.0.0.54+9`). The real
  convention (confirmed against the pubspec.yaml inline comment "has to end in .0" and Drew's ask):
  msix_version = `1.<minor>.<patch>.0` — major fixed at 1 (independent of the app's own pre-1.0
  major), build suffix dropped entirely, last field is ALWAYS literal 0 (Microsoft Store
  requirement, not a build counter).
- Test-first: added `test_msix_version_mirrors_minor_patch_and_always_ends_in_zero` +
  `test_msix_version_drops_build_suffix_keeps_last_field_zero` to `test_sync_version.py` (also had
  to add an `msix_version:` line to the test fixture's `_write()` helper — it was missing entirely,
  so `update_pubspec`'s msix logic was never exercised by any prior test). Confirmed RED, fixed,
  confirmed GREEN (5/5).
- Ran `make sync-version` for real: version.txt had independently been bumped to `1.5.4` (not by
  me — found already changed when I went to verify). Confirms end-to-end: `pubspec.yaml` →
  `version: 1.5.4` + `msix_version: 1.5.4.0`; `app_metadata.dart` → `appVersion = '1.5.4'`. All
  three files consistent.
- Files: `agents/tools/sync_version.py` (`update_pubspec`'s msix formula),
  `agents/tools/test_sync_version.py` (fixture + 2 new tests).

## FOLLOW-UP (2026-07-09 #4): drop '+' build-suffix support entirely (Drew: "will not work with the appstores")
- Added `_reject_build_suffix(version)` — called at the top of `read_version`, `write_version`,
  `update_pubspec`, `update_metadata`, `update_snapcraft`. Any version string containing `+` is
  rejected with `sys.exit(1)` + a clear stderr message, before anything is written. This is a policy
  change, not a parsing fix: the project no longer accepts a Flutter build-number suffix as a valid
  version anywhere in the pipeline (CLI `--set`, `version.txt` contents, or a direct call to any
  `update_*` function).
- The OLD-value-tolerant regexes in `update_pubspec`/`update_metadata` (added in the 2026-07-09 #1
  fix) are UNCHANGED and deliberately kept — they still clean up a legacy `+`-suffixed value already
  sitting in a generated file, which is a different concern (matching stale output) from whether a
  NEW version is allowed to have one (now: never).
- Test changes: replaced `test_msix_version_drops_build_suffix_keeps_last_field_zero` (which
  expected a dirty new version to succeed with the suffix silently dropped) with
  `test_rejects_new_version_with_build_suffix` (expects `SystemExit`) — the old expected behavior is
  no longer the policy. Added `UpdateSnapcraftTest` and `VersionFileValidationTest` (covers
  `read_version`/`write_version`). 9/9 green.
- Verified end-to-end: `make set-version VERSION="1.5.5+3"` fails loudly (exit 2 via mkf), leaves
  `version.txt` untouched at `1.5.4`. `make sync-version` on the real (clean) `1.5.4` still works.
- Files: `agents/tools/sync_version.py` (`_reject_build_suffix` + call sites),
  `agents/tools/test_sync_version.py` (replaced one test, added 2 new test classes).

# Neo Current Task — 2026-07-08 (historical; see top for latest)

## STATUS (2026-07-08): Astro bg fix + lint remediation DONE; judge-loop BUG-1 fixed, handed to Bob
Three pieces of work landed today, all uncommitted on top of 6b09cd9:
1. Astro background luminance-merge fix (see `PreExistingLints_Fix_2026-07-08.md` sibling doc for
   the lint-remediation half; astro fix details are in the plan file + Trin's UAT doc).
2. Pre-existing lint remediation (6 metric violations) + suppression audit (unused_element
   unsuppressed, 2 real dead-code findings fixed) — full writeup:
   `neo.docs/PreExistingLints_Fix_2026-07-08.md`.
3. Judge loop on "bob-protocol persona-switching" (broadened to full-session tool/skill usage):
   TES 86/100. Fixed BUG-1 (`agents/tools/session_trace.py` hardcoded the wrong harness's
   transcript path, silently reporting 0 via queries instead of the real 10 — added Claude Code
   support, verified). BUG-2/3/4 (stale Python-templated SKILL.md, unscoped state-file reads,
   make-chat char-limit doc placement) handed to Bob — see `agents/smith.docs/bugs.md`.

## NEXT STEP
None owed by Neo right now. If judge loop iterates again after Bob's fixes, Trin re-runs
verification, not Neo (no code changes expected in that pass).

---

## STATUS (2026-07-01): macOS ASWebAuth *bloop impl — Phase A + B DONE, handed to Trin for UAT.
Parallel track (task.md), does NOT touch F-31/window code. F-31 window convergence status below (2026-06-20) is UNCHANGED — resume there when this lands.

### Phase A (spike) — RESOLVED, no escalation needed
Plan's open question: does Google's Desktop OAuth client type accept a custom-URL-scheme redirect_uri,
or does macOS ASWebAuth need a second (iOS-type) client? Answered by evidence already in the codebase:
`oauth_redirect_handler.dart` already used `com.googleusercontent.apps.732125393297-...:/oauth2redirect`
with the existing Desktop client, shipped in v0.5.3. Google's redirect_uri validation is server-side and
scheme-based — it doesn't care how the browser was launched. So: no second client, no Cypher/Drew escalation.

### Phase B (implement) — DONE
- Added `flutter_web_auth_2: ^5.0.3` (macOS/iOS only usage; `pubspec.yaml`).
- `oauth_redirect_handler.dart`: replaced `_AppLinksRedirectHandler` (external Safari launch + `app_links`
  stream) with `_ASWebAuthRedirectHandler` (macOS) using `FlutterWebAuth2.authenticate(url:, callbackUrlScheme:)`
  — plugin owns both browser-launch and callback-capture in one call. Interface changed:
  `waitForCallback()` → `authenticate(Uri authUrl)` (now owns the launch too); `_LoopbackRedirectHandler`
  (Windows/Linux) updated to match — moved the `launchUrl` call in from `auth_service.dart` (behavior
  unchanged, same HttpServer loopback).
- `auth_service.dart`: `signIn()` now calls `_redirectHandler.authenticate(authUrl)` instead of
  `launchUrl(...)` + `waitForCallback()`. Removed now-unused `url_launcher` import.
- `app_links` dependency removed entirely (was only used by the old macOS handler) — confirmed zero
  remaining Dart references. `AppDelegate.swift`'s `application(_:open:)` override (forwarded URLs to
  app_links, with a comment already stale re: the old `works.gs.happening://` scheme) deleted as dead
  code — `ASWebAuthenticationSession` intercepts its callback scheme itself, no app-delegate path needed.
- `Info.plist` CFBundleURLTypes already registered the right reverse-client-ID scheme — no change needed.
- **AC-6 (cancel/dismiss)**: read the actual native plugin source (not just README, which documents
  nothing about error codes) — `FlutterWebAuth2Plugin.swift` maps `ASWebAuthenticationSessionError
  .canceledLogin` to `FlutterError(code: "CANCELED")`, which Flutter surfaces as
  `PlatformException(code: 'CANCELED')`. `_ASWebAuthRedirectHandler.authenticate` catches that
  specifically and returns null (routes to existing sign-in-cancelled state, same as any other null return).
- **Known limitation (flag for Smith/Trin, not a blocker)**: `flutter_web_auth_2`'s public API is only
  `authenticate()` — no programmatic dismiss for an in-flight `ASWebAuthenticationSession`. Our own
  "tap to cancel" affordance on the sign-in strip (`GoogleAuthService.cancelSignIn()` → `handler.cancel()`)
  is a documented no-op on macOS now — only the user's own tap on the *system sheet's* Cancel button ends
  it (which AC-6 already covers via the PlatformException path). This wasn't true before (the old
  `_AppLinksRedirectHandler.cancel()` could actually interrupt a pending callback) — worth a UX note.

### Self-validation (bloop rule #1) — all green
- `flutter analyze lib/ test/` — no issues.
- New `test/features/auth/oauth_redirect_handler_test.dart` (5 tests): start() returns correct redirect,
  authenticate() success/cancel(AC-6)/unrelated-failure paths, cancel() no-op doesn't throw. Uses a fake
  `FlutterWebAuth2Platform` (the plugin's own platform-interface seam) — no real system sheet needed.
- Full suite: 483/485 green. The 2 failures are the pre-existing golden failures already noted in
  CHAT.md (2026-06-23, F-31/window work) — unrelated to auth, confirmed by diff scope.
- Real `flutter build macos --debug` — succeeds. Confirms SPM resolves the plugin's native macOS
  implementation with no CocoaPods/manual install step (matches this project's SPM-only convention).
  `GeneratedPluginRegistrant.swift` now registers `FlutterWebAuth2Plugin`, no more `AppLinks`.

### Known open item from Morpheus's research — not yet checked
The `flutter_web_auth_2` README documents an open, unresolved upstream bug: errors on macOS when Chrome
is the default browser (issue #136, no workaround found). This is an Apple/plugin-level bug outside our
control. Trin's Phase C UAT should note whether it manifests in a manual smoke test (can't be exercised
by unit tests — needs a real system sheet + a machine where Chrome is default).

---

## STATUS (2026-06-20 PM): SHOW convergence COMMITTED (e4100fc) + VALIDATED. HIDE convergence DONE (unit-verified, awaiting Drew manual gate). NEXT phase: expand/collapse.

## SHOW convergence VALIDATED (build-no-strut-issues.md): every hide->show holds (0,0) thru +150/+500/+1200ms, NO drift. Re-pin (§4.3) DROPPED. Rule(b) DISPROVEN. Committed e4100fc (22 files, +2488/-483).

## HIDE convergence (this phase, *bloop impl): mirror of show.
- window_service.dart: base `hideStrip()` = prepareToHide()+resizeToMiniStrip(_fontSizePx) (Linux/macOS).
- windows_window_service.dart: `hideStrip()` override = applyState(hidden) (release strut + size mini, 1 call).
- timeline_strip _hideStrip: removed prepareToHide; now setState(isHidden) -> _hideAnim.reverse() (fade)
  -> _windowService.hideStrip(). NOTE: dispose(strut release) MOVED from before-fade to after-fade
  (inside applyState(hidden)). Behavior change worth manual-gating.
- Tests: +2 (hideStrip releases+sizes mini; hide->show round-trip). 93 window tests green, analyze clean.

## EXPAND/COLLAPSE convergence DONE (Drew: "converge on the solution we know works" + "don't change plan").
- performResize(intent) now = `applyState(intent==expanded ? expandedShown : collapsedShown)`. Replaces
  _doExpand/_doCollapse for the ExpansionController-driven path (hover/click expand).
- KEY: base strategy.expand/collapse already == applySize but WITHOUT position (resize in place, no
  re-pin). applyState reserves THEN applySize AT reserved origin (0,0) -> re-pins every transition =
  the stranding fix. Reservation stays COLLAPSED band during expand (applyReservation uses _bandHeightPx
  = collapsed); expanded card overlays downward, same as today + re-pinned.
- _doExpand/_doCollapse STILL used by reassertAppBar (line ~116), updateHeights/font (~222),
  _onDisplayChangedInner (~530) — those are separate convergence items (display/font), NOT touched.
- 93 window + 190 timeline tests green, analyze clean. VALIDATED (build-hide-show-expand-collapse-good.md:
  all 95 GEO samples = (0,0), no drift) + COMMITTED cb8c1e5.

## DISPLAY/FONT/REASSERT converged (513d928): reassertAppBar + updateHeights + _onDisplayChangedInner
now call _reapplyCurrentState() = applyState(current). Deleted _doExpand/_doCollapse +
WindowResizeStrategy.expand/collapse (dead). Test: reassert Linux setPosition 3->4; strategy test ->
applySize. 93 window + 190 timeline green. Net -20 lines (deletion payoff started).

## CONVERGENCE COMPLETE (Windows-first): EVERY transition (init/show/hide/expand/collapse/display/font/
reassert) routes through applyState now. refresh=calendars-only. Commits: e4100fc, cb8c1e5, 513d928.
## DEFERRED (per plan, separate gating): Linux/macOS convergence (still use resizeToMini/Full +
onShow/HideStrip base path); fold ExpansionController into StripController (§4.1); wire StripController
(showStrip/hideStrip/performResize call applyState directly today, mirroring init — works + validated).
## MANUAL SANITY (when convenient): font-size change (settings), multi-monitor display change, reassert.

## CONVERGENCE FIX (Drew directive: "make show do what init does. Don't do something new. Use a path we know works.")
- Side-by-side trace (build-still-below-strut.out): init reserves FIRST -> sizes at reserved origin
  -> presentInitialFrame (shrink-settle+pin) => stays (0,0). OLD show path = resizeToFullStrip (sizes
  BEFORE reserving) -> onShowStrip (reserve+setPosition), NO present => drifts to (0,73) at +500ms.
  Also "redraws twice" = the two separate resize/reposition ops.
- FIX = make show identical to init:
  - window_service.dart: new `showStrip()` base = legacy `resizeToFullStrip()+completeShow()`
    (Linux/macOS strut lives in onShowStrip - untouched, safe).
  - windows_window_service.dart: `showStrip()` OVERRIDE = `applyState(collapsedShown)` +
    `presentInitialFrame()` (= afterWindowShown/init sequence).
  - timeline_strip.dart `_showStrip`: setState(isHidden=false) FIRST (so present has right frame),
    then single `await _windowService.showStrip()`, then `_hideAnim.forward()`. Dropped the
    resizeToFullStrip + completeShow calls.
- DROPPED the onWindowMoved re-pin (it was a NEW mechanism; Drew said don't). Plan §4.3 DEMOTED to
  contingent (§2b): only add if manual gate STILL shows drift after pure convergence.
- TEST: reverted the speculative rule-(b)/settle/onMove harness machinery. New group 'show converged
  onto init path' asserts reserve-before-size + present (init order) + stays within band. 91 window
  tests green, `flutter analyze lib` clean. (L-006: async OS relocation is real-run only = manual gate.)
- Files: app/lib/core/window/window_service.dart, windows_window_service.dart,
  app/lib/features/timeline/timeline_strip.dart, app/test/core/window/windows_window_service_test.dart,
  docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md (§2b, §6).

## PRIOR (2026-06-20 AM): repro harness landed then reverted (see above). Manual gate: init OK, hide OK, SHOW below strut.

## MANUAL GATE 2026-06-20 (build-show-below-strut.out)
- init worked (correct this time); hide worked; SHOW expanded BELOW strut; refresh did NOT restore
  (expected — Step 1 made refresh calendars-only, no window op).
- GEO trace: onShowStrip set pos=(0,0); onShowStrip/resizeToFullStrip +500ms = pos=(0,73). The OLD
  bespoke show path (_showStrip -> resizeToFullStrip + completeShow/onShowStrip) re-registers ABM_NEW
  at (0,0) after hide's ABM_REMOVE, OS async-relocates to (0,73) ~150-500ms later, nothing re-pins.
  = the exact REMOVE->NEW relocation root cause (plan §2). Show path is NOT wired through applyState
  yet (Step 2 not done).

## REPRO DONE (Drew directive: "before changing anything - update the test harness to repro")
- test/core/window/windows_window_service_test.dart:
  - FakeWin32Desktop now models RULE (b) (plan §7b): releaseBand() arms _strutReleased; registerAppBar()
    (called from FakeWindowsAppBar.register) sets _pendingRelocation if REMOVE->NEW while at band origin;
    settle() performs the async move to (0, band/dpr) + fires onMove (the WindowListener seam). onMove
    left null = current unfixed code -> nothing re-pins.
  - New group 'hide->show relocation (REGRESSION)': init+present -> hide -> show -> settle(); asserts
    desktop.position==Offset.zero. FAILS as designed: Actual Offset(0,55). 14 prior tests green.
- mkf.py tail-printer crashes on cp1252 when '->' arrow (→) is in the FAILURE summary tail (exit 2),
  but the test run itself completes + writes build.out. Pre-existing latent tooling bug. Scrape build.out.

## OLD STATUS (2026-06-19): Sliver FIXED + confirmed. init position below strut fixed via reserve-then-position. GEO logging re-added.

## Init POSITION bug (below strut) — root cause + fix
- applyState was: applySize(position) THEN applyReservation(reserve). ABM_SETPOS (the reserve) can
  MOVE the AppBar window, and nothing repositioned it after → strip lands below its own strut.
- The old working _handleFirstShow did reserve→setPosition (position AFTER reserve). I'd inverted it.
- The "17:26 trace" I'd encoded as oracle was actually the BUGGY init (the "worked perfectly" was
  post-reload, which re-positions). Drew's order instinct was right.
- FIX: applyState now reserves FIRST, then positions. applyReservation returns Offset? (the reserved
  band origin); applyState applySize at that origin. Windows applyReservation returns
  Offset(workAreaOrigin.dx, rcTop/dpr). Base returns null → caller uses workAreaOrigin.
- onShowStrip (hide→show path, not yet wired through applyState) also repositions AFTER reserve now.
- Regression test: 'positions the window at the reserved band origin' (rcTopToReturn=100 → setPosition(0,100)).
- Oracle test flipped to register→reserve→resize. +86 window tests green.

## GEO[] logging is PERMANENT — Drew directive "DO NOT TAKE OUT DEBUG LOGGING" (2026-06-19).
(logGeometry in applyState + Windows presentInitialFrame:after/onShowStrip:end. Keep it.)

## RELOAD (refresh button) bug — FIXED 2026-06-19
- "Reload" = the refresh toolbar button (Icons.refresh), NOT Flutter hot reload.
- It fired THREE unawaited ops concurrently (timeline_strip ~1014): _resetToFreshCollapsedState
  (collapse via ExpansionController) + calendar refresh + reassertAppBar. The two WINDOW ops raced
  → toggled below/above the strut.
- FIX (use the same flow as everything else):
  1. Windows reassertAppBar now = `_appBar.dispose(); await applyState(collapsedShown);` — drops the
     bar (ABM_REMOVE re-broadcast) then re-applies via the SINGLE applier (reserve→position). No more
     bespoke performResize/setPosition sequence. Test: dispose→register→reserve + setPosition(reserved).
  2. Refresh button serialises the window ops: `await _resetToFreshCollapsedState(); await reassertAppBar();`
     (data refresh stays independent). _resetToFreshCollapsedState now sendAndAwait(collapsed).
- +87 window / +190 timeline green.

## ALL window-state traces now DBG (_log.fine), per Drew. GEO[]/appbar/applyState logs are kept (don't remove) but at fine level.

## INIT POSITION bug #2 (present nudge) — FIXED + now guarded
- GEO trace 19:55 proved it: GEO[applyState]=pos(0,0) THEN GEO[presentInitialFrame:after]=pos(0,73).
  The present's 1px nudge GREW the window to 73.5 > band 73 → Windows relocated the AppBar window
  into the work area (y=73, below its own strut). applyState had it right; the nudge stranded it.
- FIX: presentInitialFrame now SHRINKS (h-1 → h, stays within band) + pins origin after. windows svc.
- HARNESS FIX (Drew *learn → L-006): mocks asserted CALLS, never the OS reaction, so they passed while
  the app failed. Added FakeWin32Desktop modeling the Win32 relocation rule (window taller than band →
  pushed to band height), wired to mockWM setSize/setPosition/getPosition + the AppBar fake. New test
  'init + present leaves the strip IN the strut' asserts desktop.position==(0,0). PROVEN: it fails on
  the buggy grow (Actual Offset(0,55)), passes on the fix. +88 window tests green.
- Lesson recorded: docs/LESSONS.md L-006; memory feedback_model_os_behavior_in_fakes.md.

## DPI rounding hardening (Drew asked) — DONE
- Band was (h*dpr).round() physical; window sized in logical, rounded to physical by window_manager
  independently → at fractional DPI window can round UP while band rounds DOWN → window 1px taller
  than band → relocation. FIX: _bandHeightPx = (h*dpr).ceil() (band >= window physical, any rounding).
- Made FakeWin32Desktop DPI-aware (window physical = ceil(size*dpr), compare in physical). Added
  dpr=1.1/font=16 test. PROVEN: round-band fails (Offset(0,57.3)=63/1.1), ceil-band passes. +89 green.
- L-006 extended with the DPI corollary.

## ROOT CAUSE of refresh/show below-strut (confirmed by +Nms probes, build.below.out 22:55):
async OS relocation to (0,73) ~150ms after we set (0,0) — outside AsyncGate. Fires on ABM_REMOVE→NEW
cycle while window at (0,0); NOT on fresh init nor when already at (0,73). Drew's ABM_REMOVE instinct.

## CONVERGENCE PLAN documented: docs/WINDOW_ENTRYPOINT_CONVERGENCE_PLAN.md
Only INIT uses applyState; all other entrypoints (refresh/hide/show/expand/collapse/display/font) are
bespoke paths → that divergence IS the recurring bug. Converge ALL through applyState via one gate
(StripController). Rule: ABM_REMOVE ONLY on →hidden; shown→shown re-SETPOS without teardown (kills
refresh drift at root). One legit REMOVE→NEW (hide→show) handled by onWindowMoved re-pin.
Migration: (1) refresh/reassert→applyState no dispose [tests ABM_REMOVE hyp], (2) hide/show, (3)
onWindowMoved re-pin + model it, (4) expand/collapse+display/font, fold ExpansionController.

## CONVERGENCE STEP 1 DONE (2026-06-19)
- Refresh button → calendars-only: dropped reassertAppBar (the strut band-aid that caused the
  ABM_REMOVE→NEW drift). Now just calendarController.refresh() + _resetToFreshCollapsedState (view reset).
- Added base button press feedback to _IconButton (now StatefulWidget): AnimatedScale 0.86 on press +
  shadow sink. Drew: "would be nice if it visually responded to the click."
- +190 timeline green, analyze clean.
- Decisions baked into plan §2a: refresh=calendars only; onWindowMoved re-pin APPROVED; animation DEFERRED.

## NEXT: Drew tests refresh (should NOT strand strip now; button should depress). Then STEP 2:
converge hide/show through applyState (controller.hide/show), delete resizeToMini/Full + onHide/ShowStrip;
hide becomes the only ABM_REMOVE → validates the hypothesis. STEP 3: onWindowMoved re-pin + model it.

## What fixed it (root causes, both proven by GEO[] trace)
1. SLIVER: presentInitialFrame fired ~150ms BEFORE Flutter's first frame (initialize() runs before
   runApp()). RedrawWindow can't composite a frame that doesn't exist. FIX: defer present to
   addPostFrameCallback (post-first-frame) + make present a 1px size-settle (h+1→h) — a metrics
   change is what makes the ANGLE/D3D engine present (same reason mouse-over fixed it). Verified:
   afterWindowShown:applied .675 → presentInitialFrame .869 (+194ms, post-frame). NOT a position bug
   (Win32 reported pos=(0,0) size=3840x72 throughout).
2. HEIGHT DESYNC (72.5 vs 69.5): timeline_strip _collapsedHeight subtracted a magic 3 from
   WindowService.getCollapsedHeight(). FIX: _collapsedHeight => getCollapsedHeight() (single source).

## Seam + tests (the confirm-the-fix harness)
- windows_app_bar.dart: WindowsAppBar interface + Win32AppBar FFI impl (register/reserveTopBand/
  reassertTopBand/dispose/presentFrame). All FFI out of the service.
- windows_window_service_test.dart: FakeWindowsAppBar; ORACLE test encodes the verified 17:26 trace
  (resize→reserve order, present deferred). +85 window tests green via `make win-test`.

## Debug logging REMOVED (logGeometry + GEO[] calls gone from window_service + windows_window_service).

## NEXT (Step 3 — refactor, not bugfix): wire hide/show/expand through StripController/applyState so
there is ONE path (Drew's "fix here fixes everywhere"). Currently only INIT uses applyState; runtime
hide/show use resizeToFull/Mini + onShow/HideStrip, expand uses _doExpand. They WORK, but unifying
removes the last drifting paths. Then fold ExpansionController into StripController; drop dead
resizeToMini/Full. Consider: commit this milestone first.

## Manual gate result (2026-06-19, build/build.out 14:33)
- Init: sliver persisted; strip below strut. applyState logged origin=(0,0), reserve rcTop=0,
  presentInitialFrame (RedrawWindow) RAN but did NOT composite. Mouse-over composited (as before).
- Hot reload repositioned correctly; hide→show put strip below strut again.
- LOG PROVED waitUntilReadyToShow does NOT await its callback (afterReadyToShow ran at .380 while
  the callback's moveToDisplay/performShow ran at .743/.808). BUT afterWindowShown (.810) still ran
  AFTER performShow — so the ordering choice was correct; the remaining bugs are OS-visual, not ordering.
- So: (a) RedrawWindow alone is insufficient to composite this frameless/AppBar window;
  (b) position-below-strut is a workAreaOrigin-vs-display-top anchor issue (suspected) — need runtime data.

## SEAM DONE (the "way to confirm the fix")
- NEW app/lib/core/window/windows_app_bar.dart: `WindowsAppBar` interface + `Win32AppBar` FFI impl.
  Moves ALL FFI (SHAppBarMessage/FindWindow/RedrawWindow + APPBARDATA struct) out of the service.
  Methods: register / reserveTopBand(widthPx,heightPx)->rcTop / reassertTopBand / dispose / presentFrame.
  Sync FFI ⇒ dropped the old _appBarBusy reentrancy guard (no longer meaningful).
- windows_window_service.dart now depends on injected WindowsAppBar (default Win32AppBar).
- NEW app/test/core/window/windows_window_service_test.dart: FakeWindowsAppBar; asserts init order
  (register→reserve→present once), reserve dims (px), hidden→dispose, overlay→no-reserve, register-once,
  hide→show re-register+reserve. +83 window tests green, analyze clean (make win-test).

## DEBUG LOGGING ADDED (remove after fix)
- base WindowService.logGeometry(label): logs GEO[label] pos/size/workAreaOrigin/displaySize/dpr.
- Called in applyState, resizeToFullStrip, resizeToMiniStrip; Windows afterWindowShown:end, onShowStrip:end.

## NEXT: Drew runs `make run-windows`; do init + mouse-over + hide→show; Neo scrapes build.out GEO[] lines.
Then: fix present (try SetWindowPos(SWP_FRAMECHANGED) or present after first Flutter frame) + position
anchor (likely position strip at display top, not workAreaOrigin). Add regression tests via the seam.

## Step 2 DONE — init rewrite (windows_window_service.dart), awaiting manual gate
- Init now applies final state ONCE post-show via `afterWindowShown` override:
  `applyState(StripState.collapsedShown)` → `presentInitialFrame()`. Chosen `afterWindowShown`
  (not `afterReadyToShow`) because it runs INSIDE the readyToShow callback's await chain right
  after `performShow` — guaranteed post-show regardless of whether `waitUntilReadyToShow` awaits
  its outer callback. This sidesteps the B2 race entirely (no probe needed).
- DELETED: `onWindowFocus`, `_handleFirstShow`, `_firstShowHandled`, `_safetyNet`, the
  `afterReadyToShow` safety-net override, the `beforeShow` override (AppBar pre-register), and the
  `with WindowListener` mixin + its add/removeListener calls. Removed the `actual window size=`
  diagnostic logs.
- NEW `applyReservation(StripState)` (Windows): pure reservation, NO geometry (applyState already
  sized/placed). shown+reserved → create handle if null + `_reserveSpace()` (QUERYPOS/SETPOS at
  collapsed height); hidden or overlay → `_disposeAppBar()`. Keeps `_appBarBusy` guard. Warns if
  ABM_QUERYPOS returns non-zero rcTop (B5).
- NEW `presentInitialFrame()` (Windows): FindWindow(FLUTTER_RUNNER_WIN32_WINDOW) →
  `RedrawWindow(hwnd, nullptr, null, RDW_INVALIDATE | RDW_UPDATENOW)`; null-hwnd guard. win32 6.3.0.
- Refactored helpers: `_createAppBarHandle()` (FindWindow + ABM_NEW) + `_reserveSpace()`
  (QUERYPOS/SETPOS, no geometry) extracted; `_reserveCollapsedSpace()` = `_reserveSpace` + collapsed
  geometry (legacy display-change/reassert paths); `_registerAppBar()` = handle + reserveCollapsed.
- macOS/Linux untouched: neither overrides `afterWindowShown`/`afterReadyToShow` in a conflicting
  way (Linux uses afterWindowShown for strut — separate subclass; macOS defers performShow).
- Verified: `make win-test FILE=test/core/window/` → analyze clean + 75 tests green.

## MANUAL GATE (Drew) — the thesis
`make run-windows` (kill any stray running instance first — it pollutes build.out). PASS =
full-width strip composites IMMEDIATELY on launch (no 1px sliver, no mouse-over needed). Also
sanity: hide→show, expand/collapse, multi-monitor still work (those still use the OLD runtime
paths — unchanged by Step 2).

## Makefile fix (2026-06-19)
- Added `win-test` target (analyze + test, no bash `ulimit`); added to MKF_TARGETS. Made `analyze`
  skip `ulimit` on Windows. Run `make` from REPO ROOT.

## STEP 3 — NEXT: wire StripController into the app (callers)
- timeline_strip.dart: replace ExpansionController + _isHidden + prepareToHide/resizeToMini/Full/
  completeShow sequencing with StripController.collapse/expand/hide/show. Widget keeps view-only
  anim (_hideAnim, height tween) and listens to controller.state.
- app.dart: construct/own StripController; pass to TimelineStrip.
- B4: route display-change + font-size (updateHeights) through StripController.reapply().
- Fold ExpansionController fully into StripController; retire reassert hack; drop dead
  resizeToMini/Full once subsumed.

Plan: docs/WINDOW_STATE_REFACTOR_PLAN.md · Morpheus review (binding): docs/WINDOW_STATE_REFACTOR_REVIEW_2026-06-17.md

## Step 1 DONE — foundation (no callers yet)
New files:
- `app/lib/core/window/strip_state.dart` — `StripState {collapsedShown, expandedShown, hidden}` + isShown/isExpanded.
- `app/lib/core/window/async_gate.dart` — generic `AsyncGate<T>`: one-slot last-wins serialiser
  (extracted/generalised from ExpansionController's inline loop). Coalesces identical pending,
  supersedes different pending (completes the superseded future — no dangle), eager `_settled`
  dedup, `force` flag for geometry re-apply, error propagates + loop survives.
- `app/lib/core/window/strip_controller.dart` — `StripController extends ChangeNotifier` (the MVC
  controller / model owner). Transition API: collapse/expand/hide/show + reapply(force). Single
  serialised entry point (AsyncGate). Delegates OS geometry to `WindowService.applyState`.
WindowService changes:
- `applyState(StripState)` — idempotent applier: `_sizeFor(state)` → `strategy.applySize(size, position: origin)`
  → `applyReservation(state)`. Keeps legacy `_isExpanded` in sync during migration.
- `_sizeFor(state)` — full-width×collapsed/expanded, mini×collapsed for hidden.
- `@protected applyReservation(StripState)` — base no-op (named, NOT `_`-prefixed, so subclasses in
  other files can override — Dart private is library-scoped; plan's `_applyReservation` would NOT work).
- `@protected presentInitialFrame()` — base no-op (Windows FFI RedrawWindow lands in Step 2).
Tests (all green, +75 window suite, analyze clean):
- `async_gate_test.dart` (8), `strip_controller_test.dart` (6), `applyState` group in `window_service_test.dart` (6).
- StripController test reuses `window_service_test.mocks.dart` + inline DisplayService stubs; `_FakeWindowService` overrides applyState.

## STEP 2 — NEXT (the thesis; manual-Windows gate per review B2)
1. Probe what `waitUntilReadyToShow` actually does (one logged run) — to know what to delete.
2. Rebuild Windows init as a deterministic awaited chain: create → performShow → applyState(collapsedShown)
   → presentInitialFrame(). Pre-show config (strategy.initialize, moveToDisplay, beforeShow, setAsFrameless)
   stays in the ready-to-show callback; show+apply+present become awaited steps in initialize().
3. DELETE onWindowFocus / _safetyNet / _firstShowHandled / _handleFirstShow.
4. Implement WindowsWindowService.applyReservation (B5: keep _appBarBusy guard + rcTop feedback;
   pure reservation, NO geometry — applyState already applied size) and presentInitialFrame
   (RedrawWindow(hwnd, NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW), null-hwnd guard).
5. Wire StripController into TimelineStrip + app.dart (this is where callers appear; may be Step 3).
6. MANUAL GATE: `make run-windows` → full strip on launch, no mouse-over needed.
   Tests can't see the compositing bug — Drew verifies.

## Owed cleanup (do in step 2)
- Remove two `actual window size=${await wm.getSize()}` diagnostic logs in windows_window_service.dart.

## Later steps (review §6 / B4)
- Migrate hide/show/expand/collapse + display-change + font-size onto StripController (B4: those are
  extra geometry paths — must re-apply current state, not stay separate).
- Fold ExpansionController fully into StripController; retire reassert hack; drop dead resizeToMini/Full.
- Capture macOS/Linux constraints in plan "Other platforms" section (B3) for separate scheduling.

## Build/test notes
- Use the Makefile, not direct flutter, for builds/tests (Drew preference). `make test FILE=test/core/window/`.
- `make analyze` / `make lint-style` FAIL on Windows: `make analyze` chains a bash `ulimit` (absent under
  Windows sh) → exit 2; and a backgrounded app instance pollutes build.out so the wrapper tail hides
  real output. For a clean analyzer signal: `flutter analyze lib test integration_test` directly.
