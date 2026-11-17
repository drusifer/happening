# Neo Agent State — Native Window & Display API Refactoring & Linux Shadow Fix

## Context
- **Task**: Refactor `happening` off `package:window_manager/legacy.dart` and `package:screen_retriever/legacy.dart` onto modern native APIs (`0.7.0` / `0.4.0`), fix Linux startup visibility, and eliminate floating shadow artifacts.
- **Key Completed Changes**:
  1. **Phase 1 (`screen_retriever` -> `DisplayManager`)**:
     - Updated [screen_retriever_adapter.dart](file:///var/home/drusifer/Projects/happening/app/lib/core/display/screen_retriever_adapter.dart) to wrap `DisplayManager.instance` with safe `dispose()` in `finally` blocks.
     - Removed redundant `ScreenRetriever` parameters across all window services and tests.
  2. **Phase 2 (`window_manager` -> `WindowAdapter` / `NativeWindowAdapter`)**:
     - Created [window_adapter.dart](file:///var/home/drusifer/Projects/happening/app/lib/core/window/window_adapter.dart) defining Flutter-typed contracts over `WindowManager.instance.getCurrent()!`.
     - Preserved exact Linux GTK setup order (`titleBarStyle = hidden` before `setSize`, `setFrameless(true)`, `bounds` in `setPosition`).
     - Kept startup initialization clean and synchronous with Flutter's widget lifecycle.
  3. **Phase 3 (Linux Dynamic Window Shadow)**:
     - Added `setHasShadow(bool)` to `WindowAdapter` and `NativeWindowAdapter`.
     - In [window_service.dart](file:///var/home/drusifer/Projects/happening/app/lib/core/window/window_service.dart), added `updateShadow(state)` inside `applyState`:
       - `collapsedShown`: `hasShadow = true` (displays subtle bottom border shadow under the 45px dock bar).
       - `expandedShown`: `hasShadow = false` (removes the floating 280px rectangular window shadow across underlying windows).
       - `hidden`: `hasShadow = false`.
  4. **Codebase Cleanup**:
     - Removed temporary C++ diagnostic logging from `my_application.cc` and `linux_dock_window_manager_plugin.cc`.
     - Retained debug file logging in `main.dart` for development builds.

## Verification Status
- `bobp make analyze`: 0 issues found.
- `bobp make test FILE=test/core/window`: 97/97 passed.
- `bobp make test FILE=test/core/display`: 49/49 passed.
- `bobp make test FILE=test/app_test.dart`: 7/7 passed.
- `bobp make build-linux`: release bundle built successfully.
- UAT verified by user: window displays properly, reservations hold, and shadow behaves cleanly.

## Ready For
- Commit and push changes on `main`.
