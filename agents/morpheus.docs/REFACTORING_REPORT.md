# Refactoring Report — Happening v0.1

**Author**: Morpheus (Lead SE)
**Date**: 2026-02-27
**Target**: Neo (Senior SWE)

---

## 1. Executive Summary
The current implementation of Sprint 2 is functional and passes all tests (83/83 GREEN). However, the `HappeningApp` and `TimelineStrip` classes have become "God Objects" that violate the Single Responsibility Principle (SRP). To ensure long-term maintainability and support for Sprint 3 (Settings, Multi-Calendar), we must decouple the core services from the UI layer.

---

## 2. Identified Code Smells

### A. Bloated Root Widget (`HappeningApp`)
- **Issue**: `app.dart` contains OAuth flow logic, file-based token persistence, polling logic, and root UI switching.
- **Impact**: Hard to test auth logic in isolation; risk of "shotgun surgery" when adding new auth providers or storage backends.

### B. Logic Leaking into UI (`TimelineStrip`)
- **Issue**: `TimelineStrip` handles its own hit-testing (`_eventAtX`) and directly calls `windowManager` to resize the window on hover.
- **Impact**: Timeline math is duplicated between `TimelinePainter` and `TimelineStrip` handlers. Window resizing is hard-coded to specific heights.

### C. Concrete Dependency on File System
- **Issue**: `_tokensFile()` and `_loadCredentials()` in `app.dart` are hard-coded to use `dart:io` and `~/.config/happening`.
- **Impact**: Prevents easy mocking for unit tests; breaks the Interface Segregation Principle since `HappeningApp` must know about the file system.

---

## 3. Recommended Refactorings

### Recommendation 1: Implement `AuthService` & `TokenStore`
Move all logic from `app.dart` into concrete implementations of the existing abstract interfaces:
1. **`FileTokenStore`**: Implements `TokenStore`. Handles JSON serialization to `~/.config/happening/tokens.json`.
2. **`GoogleAuthService`**: Implements `AuthService`. Encapsulates `clientViaUserConsent` and `autoRefreshingClient`.

### Recommendation 2: Centralize Timeline Geometry
`TimelineLayout` should be the "Single Source of Truth" for all coordinate math.
- **Action**: Move `_eventAtX` from `TimelineStrip` into `TimelineLayout`. 
- **Benefit**: Unified logic for both painting and hit-testing.

### Recommendation 3: Abstract Window Management
The `WindowService` is currently only used for initialization.
- **Action**: Add `expand()` and `collapse()` methods to `WindowService`.
- **Benefit**: `TimelineStrip` just calls `WindowService.expand()`, hiding the implementation details of `windowManager`.

### Recommendation 4: Decouple Polling Logic
- **Action**: Move the `Timer.periodic` and event fetching loop into `EventRepository` or a new `CalendarController`.
- **Benefit**: `HappeningApp` becomes a simple switch that listens to a stream of events.

---

## 4. Proposed Action Plan (Sprint 3)
1. **S3-Refactor-01**: Extract `FileTokenStore` and `GoogleAuthService`.
2. **S3-Refactor-02**: Move hit-testing to `TimelineLayout`.
3. **S3-Refactor-03**: Enhance `WindowService` with semantic resizing methods.
4. **S3-Refactor-04**: Move polling loop out of root `StatefulWidget`.

---

*Refactoring is the process of changing a software system in such a way that it does not alter the external behavior of the code yet improves its internal structure.* — Martin Fowler
