# Linux Wayland Simplification Sprint Plan

**Date**: 2026-04-25T16:41  
**Scrum Master**: Mouse  
**Source Stories**: `agents/cypher.docs/linux_wayland_simplification_sprint_stories_2026-04-25T16:41.md`  
**Architecture**: `agents/morpheus.docs/LINUX_WAYLAND_SIMPLIFICATION_ARCH_2026-04-25T16:41.md`

## Phase A — Capability And Guardrails

### LWS-A1: Lock Linux Mode Availability
- **Goal**: Preserve safe UI behavior before native code is removed.
- **Files**:
  - `app/lib/core/settings/settings_service.dart`
  - `app/lib/core/window/interaction_strategy/linux_window_interaction_strategy.dart`
  - `app/test/core/settings/settings_service_test.dart`
  - `app/test/core/window/window_interaction_strategy_test.dart`
- **Risk**: Medium
- **Tests**: Linux unsupported/verified availability tests; settings hides unsupported transparent mode.
- **Assigned**: @Neo

### LWS-A2: Define Manual Smoke Matrix
- **Goal**: Write the X11/XWayland and Wayland smoke checklist before implementation claims support.
- **Files**:
  - `agents/trin.docs/`
  - `agents/morpheus.docs/LINUX_WAYLAND_SIMPLIFICATION_ARCH_2026-04-25T16:41.md`
- **Risk**: Low
- **Tests**: Checklist includes startup, top alignment, always-on-top, transparency, click-through, focus hotkey, Escape.
- **Assigned**: @Trin/@Morpheus

## Phase B — Remove Native Reservation Path

### LWS-B1: Simplify Linux Runner
- **Goal**: Remove X11 strut/DOCK, Wayland layer-shell, and C++ settings parsing.
- **Files**:
  - `app/linux/runner/my_application.cc`
  - `app/linux/runner/CMakeLists.txt`
- **Risk**: High
- **Tests**: `make build-linux`; smoke startup.
- **Assigned**: @Neo

### LWS-B2: Preserve Minimal Transparent Startup
- **Goal**: Keep only runner code required for Flutter startup, icon, and transparent background behavior.
- **Files**:
  - `app/linux/runner/my_application.cc`
  - `app/lib/core/window/window_service.dart`
- **Risk**: Medium
- **Tests**: Linux build; no black startup window; no app icon regression if verifiable.
- **Assigned**: @Neo
- **Depends on**: LWS-B1

## Phase C — Product Surface And Docs

### LWS-C1: Update Mode Gating And Settings Copy
- **Goal**: Linux settings reflect verified support only.
- **Files**:
  - `app/lib/features/timeline/settings_panel.dart`
  - `app/lib/core/settings/settings_service.dart`
  - relevant tests
- **Risk**: Medium
- **Tests**: Linux hidden unsupported modes; Windows/macOS unchanged.
- **Assigned**: @Neo
- **Depends on**: LWS-A1

### LWS-C2: Update Architecture And Requirements Docs
- **Goal**: Remove stale claims that Linux defaults to shell-reserved panel behavior.
- **Files**:
  - `docs/ARCH.md`
  - `docs/DECISIONS.md`
  - `docs/PRD.md`
  - `agents/oracle.docs/LESSONS.md` if a new lesson is learned
- **Risk**: Low
- **Tests**: Documentation references match implemented behavior.
- **Assigned**: @Oracle/@Morpheus
- **Depends on**: LWS-B1

## Phase D — Verification Gate

### LWS-D1: Automated Regression
- **Goal**: Prove simplification did not regress existing desktop behavior.
- **Files**: test suite and build logs
- **Risk**: Medium
- **Tests**: `make format`, `make test`, `make analyze`, `make build-linux`
- **Assigned**: @Trin

### LWS-D2: Linux Real-Session UAT
- **Goal**: Decide whether Linux transparent mode can be exposed.
- **Files**:
  - `agents/trin.docs/`
  - `task.md`
- **Risk**: High
- **Tests**: X11/XWayland and Wayland manual smoke; record unavailable environment as blocker.
- **Assigned**: @Trin/@User
- **Depends on**: LWS-D1

## Sprint Done Criteria
- Native Linux reservation code is removed.
- Linux build passes.
- Automated test/analyze pass.
- Documentation no longer promises Linux shell reservation.
- Linux transparent support is either verified and exposed or remains hidden with evidence recorded.
