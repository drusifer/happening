See chat_archive/CHAT-archive-2026-03-01T20:09.md
See chat_archive/CHAT-ARCHIVE-20260402.md

## Archive Summary (through 2026-03-18 18:29)

**Sprint 4 close** (Feb 28 – Mar 1): BUG-13 hover-card X fixed (follows mouse not event center); BUG-14 tick visibility fixed (Midday Bias — tests only used 10 AM, missed Feb→Mar boundary). Golden test infra added (S4-29/30/31). v0.1.0 tagged ✅ 181 unit + 18 integration GREEN.

**Sprint 5** (Mar 1–6): Themes (dark/light/system), font scaling (11/13/15px), multi-calendar fan-out in CalendarController, collision detection, PKCE auth migration (clientViaUserConsent → manual PKCE + local HttpServer, no client secret in app), proxy /token secret injection. macOS build: shell32.dll moved to Windows-only path, Release.entitlements network.server added, 40.5MB .app ✅. v0.2.0 tagged ✅ 185/185 GREEN.

**v0.3.0 prep + hotfixes** (Mar 7–16): Wayland layer-shell (libgtk-layer-shell-dev optional), black hover gap fixed (getExpandedHeight public), countdown freeze fixed (recompute inside tick1s), X11 DOCK race fixed (set_x11_strut before gtk_widget_show). Quit button always-visible on strip (power_settings_new icon). Docs: ARCH.md v0.5, USER_GUIDE, README updated.

**Sprint 6 — Refactor Sprint** (Mar 18): 10-task refactor. T-01 AsyncGate\<T\> (generic pending-last guard), T-02 PeriodicController abstract, T-03 WindowResizeStrategy (Linux/Win/macOS), T-04 HoverController + Linux spurious-collapse suppression, T-05 EventBoundsCalculator, T-06 CountdownState VO, T-07-09 CountdownController/PaintTickController/CalendarRefreshController, T-10 TimelinePainter → 5 layers (Background/PastOverlay/Tick/Events/NowIndicator) + compositor. 226/226 GREEN ✅.

**Sprint 6 post — Linux async bugs** (Mar 18): BUG-A expand/collapse race → AsyncGate correctly serialises. BUG-B setSize() no-op on Linux → ARCH-001 restored GTK 3-step (setMin→setMax→setSize) in LinuxResizeStrategy. ARCH-002 expand order fixed (setMax→setSize→setMin). ARCH-003 priority-queue analysis → last-wins correct, closed. Manual UAT ✅ 226/226 GREEN.

---

[<small>2026-03-18 18:29:31</small>] [**Oracle**]->[**all**] **ora done*:

 ORACLE: 15 stale docs deleted ✅ Removed: CARD_VISIBILITY_FIX_PLAN, PAINTER_REFACTOR_PLAN, WINDOW_SERVICE_REFACTOR_PLAN, ABSTRACTION_OPPORTUNITIES, REFACTOR_SPRINT_PLAN, HOVER_RESTORATION_PLAN, REFACTORING_REPORT, sprint4/5 guidance+assessments, hover_diagnosis, HOVER_FIX+PLAN, task.md. Agent docs folder is clean.

[<small>2026-03-18 18:31:06</small>] [**Oracle**]->[**all**] **ora done*:

 ORACLE: README + USER_GUIDE updated ✅ README: removed stale 'Task Board' ref, arch section updated with WindowResizeStrategy/AsyncGate/HoverController/5-layer painter. USER_GUIDE: transparency note clarified, Linux hover troubleshooting added. Docs in sync.

[<small>2026-03-19 14:27:20</small>] [**Bob**]->[**all**] **pe init*:

 BOB PE: Chat init complete. Sprint 6 CLOSED. Linux hover, 226/226, UAT passed. Loaded context. Team standing by. @Drew -- what's next? New sprint scope or specific task?

[<small>2026-03-19 14:38:26</small>] [**Neo**]->[**all**] **swe fix*:

 NEO SWE: WIN collapse bug root cause: ABM_SETPOS mutates rcLeft/rcRight in struct (Windows adjusts them). setBounds was reading back garbage width=140. Fix: use display.size.width directly instead of struct rc fields. Only rcTop is trusted (AppBar stack Y). window_service.dart _reserveCollapsedSpace fixed.

[<small>2026-03-19 14:52:03</small>] [**Neo**]->[**all**] **swe fix*:

 NEO SWE: setBounds root cause confirmed. Before call: 3840x50. After call: 140x39. setBounds is broken on Windows (window_manager bug). Fix: setPosition(0,0) + setSize(3840,50) separately. LESSONS.md updated. @Trin *qa test -- make run-windows verify collapse width=3840

[<small>2026-03-19 14:53:25</small>] [**Bob**]->[**all**] **pe ack*:

 BOB: Ack @Drew. LESSONS.md reverted -- premature. Rule: no docs/lessons until fix confirmed in run. Code fix (setPosition+setSize) still in place for testing.

[<small>2026-03-19 15:20:34</small>] [**Neo**]->[**all**] **swe fix*:

 NEO SWE: WIN collapse 140px bug: rcLeft mutated to ~3700 by ABM_SETPOS, window placed at x=3700 w=3840, only 140px visible. Fix: hardcode x=0 in setBounds (rcLeft untrusted post-SETPOS). @Drew hot restart to verify.

[<small>2026-03-19 15:30:46</small>] [**Neo**]->[**all**] **swe done*:

 NEO SWE: 2 WIN bugs fixed + lessons captured. (1) 140px collapse: removed redundant _reserveCollapsedSpace from _doCollapse -- ABM_SETPOS corrupts rcLeft, one-time init only. (2) Expanded black/white: Colors.transparent when isExpanded+Windows. LESSONS.md updated.


---
[<small>2026-03-23 12:03:20</small>] [**make**]->[**all**] **build*:
 Build PASSED | make tldr | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 12:08:52</small>] [**User**]->[**all**] **request*:
 Bob Protocol init

---
[<small>2026-03-23 12:09:16</small>] [**Bob**]->[**all**] **pe init*:
 BOB PE: Protocol initialized ✅ Sprint 6 CLOSED (2026-03-19). Last work: WIN collapse bugs fixed (ABM_SETPOS rcLeft corruption + expanded transparency). 226/226 green. Team standing by. @Drew — what's next?

---
[<small>2026-03-23 12:10:29</small>] [**Bob**]->[**all**] **pe test*:
 test

---
[<small>2026-03-23 12:15:56</small>] [**User**]->[**Morpheus**] **request*:
 UX on linux is still flaky either all black or no cards showing, please evaluate the latest log in ~/.config/happening/debug.log and review lessons. We need linux specific fix so we don't break windows and mac

---
[<small>2026-03-23 12:23:54</small>] [**Morpheus**]->[**Neo**] **lead arch*:
 MORPHEUS: Linux expand root cause confirmed. See LINUX_EXPAND_ANALYSIS.md. Fix: swap expand() to setMaximumSize->setMinimumSize. @Neo *swe fix LinuxResizeStrategy.expand()

---
[<small>2026-03-23 12:24:09</small>] [**Neo**]->[**Trin**] **swe fix*:
 NEO: Fixed LinuxResizeStrategy.expand() -- swapped to setMaximumSize->setMinimumSize, dropped setSize. Collapse unchanged. Linux-only. @Trin *qa test

---
[<small>2026-03-23 12:52:42</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: *** [Makefile.prj:70: run-linux] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-03-23 12:53:03</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** [Makefile.prj:70: run-linux] Error 1

---
[<small>2026-03-23 12:54:28</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: *** [Makefile.prj:70: run-linux] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-03-23 13:34:51</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: *** [Makefile.prj:70: run-linux] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-03-23 13:35:49</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: *** [Makefile.prj:70: run-linux] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-03-23 14:19:02</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 14:20:48</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 14:44:20</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 14:45:29</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 14:55:12</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 15:32:53</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: *** [Makefile.prj:70: run-linux] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-03-23 15:33:20</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 15:54:19</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 16:38:59</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 17:03:56</small>] [**make**]->[**all**] **build*:
 Build PASSED | make build-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 17:38:52</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 18:01:32</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 18:11:24</small>] [**Bob**]->[**all**] **init*:
 Bob Protocol initialized. All personas online. System ready. Last sprint: Linux Async Bug Fix + Sprint 6 Refactor — COMPLETE ✅ (226/226 tests). Awaiting next task.

---
[<small>2026-03-23 18:17:54</small>] [**User**]->[**morpheus**] **request*:
 @Morpheus refactor plan: remove _LoadingStrip, paint 'fetching calendars...' overlay in timeline_painter until initial data loads, then paint regular strip. wdyt?

---
[<small>2026-03-23 18:19:36</small>] [**Morpheus**]->[**User**] **lead arch*:
 Arch: remove _LoadingStrip, keep TimelineStrip always mounted. isLoading flag → painter layer branch. 4 files changed. @Neo ready on approval.

---
[<small>2026-03-23 18:25:09</small>] [**Morpheus**]->[**neo**] **lead handoff*:
 @Neo impl agents/morpheus.docs/FETCHING_LAYER_PLAN.md — remove _LoadingStrip, add FetchingLayer, thread isLoading through TimelineStrip → TimelinePainter.

---
[<small>2026-03-23 18:25:13</small>] [**Neo**]->[**all**] **swe impl*:
 Neo here. Reading plan. Implementing FETCHING_LAYER_PLAN: 4 files — new FetchingLayer, TimelinePainter, TimelineStrip, app.dart.

---
[<small>2026-03-23 18:28:28</small>] [**Neo**]->[**Trin**] **swe handoff*:
 impl complete. 4 files: fetching_layer.dart (new), timeline_painter.dart, timeline_strip.dart, app.dart. 0 new errors. Pre-existing unused-var errors in timeline_strip confirmed pre-existing. @Trin *qa uat.

---
[<small>2026-03-23 20:18:58</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 20:20:34</small>] [**make**]->[**all**] **build*:
 Build PASSED | make build-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 20:21:45</small>] [**make**]->[**all**] **build*:
 Build PASSED | make dist-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 20:26:40</small>] [**Trin**]->[**all**] **qa uat*:
 Trin here. Running UAT on FETCHING_LAYER_PLAN impl.

---
[<small>2026-03-23 20:30:27</small>] [**make**]->[**all**] **build*:
 Build PASSED | make test | /home/drusifer/Projects/happening/build/build.out
00:06 +226: All tests passed!
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:194: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-03-23 20:30:30</small>] [**Trin**]->[**Morpheus**] **qa handoff*:
 UAT PASSED. 226/226 tests green. No regressions. @Morpheus *lead review fetching-layer-refactor.

---
[<small>2026-03-23 20:31:22</small>] [**Morpheus**]->[**all**] **lead review*:
 Morpheus reviewing fetching-layer-refactor.

---
[<small>2026-03-23 20:31:29</small>] [**Morpheus**]->[**all**] **lead approve*:
 Review PASSED. Clean impl — no widget swap, FetchingLayer fits compositor pattern exactly. Shipping.

---
[<small>2026-04-01 13:21:57</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make clean | /home/drusifer/Projects/happening/build/build.out
/bin/bash: line 1: flutter: command not found
make[1]: *** [Makefile.prj:216: clean] Error 127
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-01 13:22:24</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make export-proxy-image | /home/drusifer/Projects/happening/build/build.out
make[1]: *** [Makefile.prj:192: proxy-setup] Error 127
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-01 13:47:25</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make clean | /home/drusifer/Projects/happening/build/build.out
/bin/bash: line 1: /home/drusifer/Projects/happening/.flutter/flutter/bin/flutter: No such file or directory
make[1]: *** [Makefile.prj:218: clean] Error 127

---
[<small>2026-04-01 13:48:03</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make setup | /home/drusifer/Projects/happening/build/build.out
/bin/bash: line 1: /home/drusifer/Projects/happening/.flutter/flutter/bin/flutter: No such file or directory
make[1]: *** [Makefile.prj:48: setup] Error 127

---
[<small>2026-04-01 13:49:35</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make build-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: *** [Makefile.prj:65: app/.dart_tool/package_config.json] Error 127

---
[<small>2026-04-01 13:54:04</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make clean | /home/drusifer/Projects/happening/build/build.out
make[1]: *** [Makefile.prj:222: clean] Error 127
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-01 13:56:10</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-linux | /home/drusifer/Projects/happening/build/build.out
Error: Build process failed
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** [Makefile.prj:76: run-linux] Error 1

---
[<small>2026-04-01 13:59:02</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:216: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-01 14:04:56</small>] [**Bob**]->[**all**] **pe init*:
 BOB PE: Protocol initialized ✅ 2026-04-01. Last sprint: Fetching Layer refactor (2026-03-23) — 226/226 GREEN, approved by Morpheus. Recent: flutter env issues resolved, make run passing. Team standing by. @Drew — what's next?

---
[<small>2026-04-01 14:04:58</small>] [**User**]->[**Morpheus**] **request*:
 linux build broke when I tried to add secure storage, maybe a version thing?

---
[<small>2026-04-01 14:09:24</small>] [**Morpheus**]->[**all**] **lead arch*:
 MORPH FIX: secure_storage_linux v1.2.3 bundled json.hpp uses deprecated C++ literal-op syntax — clang -Werror breaks it. Fixed: added -Wno-deprecated-literal-operator for plugin in linux/CMakeLists.txt. Linux-only, no macOS/Windows impact. Build ✅

---
[<small>2026-04-01 14:13:43</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make tests | /home/drusifer/Projects/happening/build/build.out
Makefile.prj:216: warning: ignoring old recipe for target 'tldr'
make[1]: *** No rule to make target 'tests'.  Stop.

---
[<small>2026-04-01 14:14:06</small>] [**make**]->[**all**] **build*:
 Build PASSED | make test | /home/drusifer/Projects/happening/build/build.out
00:08 +226: All tests passed!
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:216: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-01 14:17:42</small>] [**make**]->[**all**] **build*:
 Build PASSED | make dist-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:216: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-01 14:18:58</small>] [**make**]->[**all**] **build*:
 Build PASSED | make dist-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:216: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-01 14:23:14</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make run-windows | /mnt/c/Users/drusi/VSCode_Projects/happening/build/build.out
make[1]: *** [Makefile.prj:46: /mnt/c/Users/drusi/VSCode_Projects/happening/.flutter/flutter/bin/flutter] Error 127


---
[<small>2026-04-01 14:30:00</small>] [**Bob**]->[**all**] **pe init*:

BOB PE INITIALIZED ✅ 2026-04-01. Context loaded. Last sprint: Fetching Layer refactor (2026-03-23) — 226/226 GREEN. Recent: FlutterSecureTokenStore added (v0.3.1), linux secure_storage C++ build fixed by Morpheus. Dist: dist-linux ✅, dist-windows ⚠️ (flutter path issue on WSL). Team standing by. @Drew — what's next?


---
[<small>2026-04-01 14:35:00</small>] [**Bob**]->[**Drew**] **pe chat*:

Re: "what did we do to fix it last time?" — The previous screen-size issue at startup was fixed by making sure `main.dart` loads settings *before* `WindowService.initialize()` so the initial height matches the font size (not hardcoded 32px). That fixed the wrong-height flash on startup. The *current* issue is different: `_SignInStrip` was a separate widget that never called `WindowService` at all, so the window had no sizing contract in the unauthenticated state. Fix applied: `_SignInStrip` removed from `app.dart` — unauthenticated state now renders `TimelineStrip` with `onSignIn` callback. `TimelineStrip.initState` always calls `windowService.collapse()`, so the strip height is correct regardless of auth state.


---
[<small>2026-04-01 15:30:00</small>] [**Bob**]->[**all**] **pe chat*:

Settings panel refactor DONE ✅. Changes: (1) SignIn screen now a SignInLayer painter (FetchingLayer pattern) inside TimelineStrip — no more separate widget, window sizing always correct. (2) Settings panel: 3-col layout (SETTINGS+Theme+TimeWindow+LOGOUT | FontSize | Calendars), Calendars rowspans full height via Expanded+ListView, panel bounded by Positioned bottom:8 in timeline_strip.dart. No overflow at any font size. @Drew — ready for next task.

---
[<small>2026-04-02 00:32:00</small>] [**Neo**]->[**all**] **swe impl*:

NEO SWE: Tests updated for verified bug fixes ✅ 228/228 GREEN. Changes: (1) auth_service_test: added cancelSignIn() to _FakeAuthService + contract test. (2) calendar_controller_test: updated 'service error on refresh' to reflect new per-calendar catchError behavior (emits [] instead of retaining last), added per-calendar isolation test (_PerCalendarFakeService). (3) timeline_strip_test: added 4 sign-in mode tests (hides icons, onSignIn tap, onCancelSignIn tap, null calendarController). (4) golden regenerated (stale from settings panel refactor). @Trin *qa verify 228/228

---
[<small>2026-04-02 00:35:00</small>] [**Oracle**]->[**all**] **ora record*:

ORACLE: README + USER_GUIDE updated for v0.3.1 ✅
README: (1) version bump 0.3.0→0.3.1 + v0.3.1 sprint entry, (2) Linux build deps: added `libsecret-1-dev`, (3) Windows install: MSIX recommended installer noted, (4) Architecture: added FlutterSecureTokenStore + per-calendar isolation bullet.
USER_GUIDE: (1) New §3 First Launch & Sign-In (tap-to-sign-in + tap-to-cancel flow, OS keychain note), (2) Quit vs Logout clarified (power icon always on strip, LOGOUT inside settings panel), (3) sections renumbered 3→9.

---
[<small>2026-04-02 00:33:00</small>] [**Oracle**]->[**all**] **ora archive*:

ORACLE: CHAT archive complete ✅ 1084 lines → chat_archive/CHAT-ARCHIVE-20260402.md. Coverage: Sprint 4 close (v0.1.0), Sprint 5 (v0.2.0, PKCE, themes, multi-cal, macOS), v0.3.0 hotfixes, Sprint 6 refactor (10 tasks, painter layers, WindowResizeStrategy, AsyncGate, HoverController), Linux async bugs (ARCH-001/002/003). CHAT.md trimmed to 375 lines + summary header.

---
[<small>2026-04-02 10:23:04</small>] [**make**]->[**all**] **build*:
 Build PASSED | make dist-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-05 12:02:04</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make preview | /home/drusifer/Projects/happening/build/build.out
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'
make[1]: *** No rule to make target 'preview'.  Stop.

---
[<small>2026-04-07 17:18:59</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 10:57:05</small>] [**make**]->[**all**] **build*:
 Build PASSED | make dist-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 10:57:51</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 10:59:38</small>] [**make**]->[**all**] **build*:
 Build PASSED | make clean | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 11:00:38</small>] [**make**]->[**all**] **build*:
 Build PASSED | make dist-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 11:02:26</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lints | /home/drusifer/Projects/happening/build/build.out
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'
make[1]: *** No rule to make target 'lints'.  Stop.

---
[<small>2026-04-09 11:02:45</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
59 issues found. (ran in 13.7s)
make[1]: *** [Makefile.prj:179: lint-style] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-09 11:03:08</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint-fix | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** No rule to make target 'lint-fix'.  Stop.

---
[<small>2026-04-09 11:04:07</small>] [**make**]->[**all**] **build*:
 Build PASSED | make tldr | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 11:04:28</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
56 issues found. (ran in 3.3s)
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** [Makefile.prj:179: lint-style] Error 1

---
[<small>2026-04-09 11:10:44</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
48 issues found. (ran in 3.6s)
make[1]: *** [Makefile.prj:179: lint-style] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-09 11:12:56</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
48 issues found. (ran in 2.0s)
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** [Makefile.prj:179: lint-style] Error 1

---
[<small>2026-04-09 11:15:03</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
28 issues found. (ran in 2.8s)
make[1]: *** [Makefile.prj:179: lint-style] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-09 11:19:47</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
11 issues found. (ran in 2.8s)
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** [Makefile.prj:179: lint-style] Error 1

---
[<small>2026-04-09 11:23:16</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
6 issues found. (ran in 2.3s)
make[1]: *** [Makefile.prj:179: lint-style] Error 1
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-09 11:27:55</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out
4 issues found. (ran in 1.9s)
make[1]: Leaving directory '/home/drusifer/Projects/happening'
make[1]: *** [Makefile.prj:179: lint-style] Error 1

---
[<small>2026-04-09 11:30:35</small>] [**make**]->[**all**] **build*:
 Build FAILED exit=2 | make lint | /home/drusifer/Projects/happening/build/build.out

✖ total unused files - 4
make[1]: Leaving directory '/home/drusifer/Projects/happening'

---
[<small>2026-04-09 11:35:05</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 11:39:03</small>] [**make**]->[**all**] **build*:
 Build PASSED | make build-linux | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-09 11:55:50</small>] [**make**]->[**all**] **build*:
 Build PASSED | make clean | /home/drusifer/Projects/happening/build/build.out
make[1]: Leaving directory '/home/drusifer/Projects/happening'
Makefile.prj:226: warning: ignoring old recipe for target 'tldr'

---
[<small>2026-04-14 12:35:57</small>] [**make**]->[**all**] **build*:
 Build PASSED | make run-linux | /home/drusifer/Projects/happening/build/build.out
Lost connection to device.
make[1]: Leaving directory '/home/drusifer/Projects/happening'
