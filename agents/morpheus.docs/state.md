# Morpheus Agent State — Native Window & Display API Refactoring (Removing `legacy.dart`)

## Context
- **Architectural Review (2026-11-12)**:
  - Reviewed and approved Phase 1 & Phase 2 refactoring off `package:window_manager/legacy.dart` and `package:screen_retriever/legacy.dart`.
  - **Key Architectural Improvements**:
    1. **Single-Point Native Package Adapters**:
       - [screen_retriever_adapter.dart](file:///var/home/drusifer/Projects/happening/app/lib/core/display/screen_retriever_adapter.dart) is the sole consumer of `package:screen_retriever/screen_retriever.dart` (`DisplayManager.instance`), converting `nativeapi` display types to `DisplayInfo`.
       - [window_adapter.dart](file:///var/home/drusifer/Projects/happening/app/lib/core/window/window_adapter.dart) is the sole consumer of `package:window_manager/window_manager.dart` (`WindowManager.instance.getCurrent()`), exposing the 16-method Flutter-typed `WindowAdapter` contract.
    2. **Removed Redundant `ScreenRetriever` Dependency from `WindowService`**:
       - `DisplayService` is now the sole display dependency of `WindowService` and its platform subclasses (`LinuxWindowService`, `MacOSWindowService`, `WindowsWindowService`).
    3. **Linear `WindowService.initialize()` Lifecycle**:
       - Eliminated `ensureInitialized()`, `waitUntilReadyToShow(...)`, and `awaitReadyToShow(...)` boilerplate.
       - Preserved `TitleBarStyle.hidden` frameless shadow behavior on Linux.

## Current Task
- **Status:** Completed and Approved (`100%`)
- **Assigned to:** @Morpheus
- **Task:** Lead review of `legacy.dart` removal refactoring

## Next Steps
- Refactoring complete and verified. Ready for user testing / commit.
