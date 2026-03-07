# Morpheus Context

## Sprint 6: macOS build — 2026-03-07
- v0.2.0 shipped. Starting macOS v0.2.1 build.
- CRITICAL BLOCKER: `window_service.dart` has top-level `DynamicLibrary.open('shell32.dll')` — crashes on macOS at module load time. Must lazify + guard with Platform.isWindows.
- RISK: Release.entitlements missing `network.server` — PKCE auth binds localhost server, will fail in release build. Must add to Release.entitlements.
- Plan: MACOS_BUILD_PLAN.md. Sequence: T1 (window_service fix) → T2 (Makefile) → T3 (smoke) → T4 (window level) → T5 (docs).
- DECISION: Simplest fix = lazy init + Platform.isWindows guards (no conditional import refactor needed unless win32 fails to compile on macOS).
