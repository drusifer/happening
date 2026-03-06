# Windows Build Strategy

This document outlines the strategy for enabling `happening` to be built, run, and tested on Windows, ensuring no disruption to existing Linux and macOS functionality.

## 1. Summary

The core application has no Windows-specific blockers. The primary challenges are in the developer tooling, specifically the `Makefile` and `setup.sh` script, which are designed for a Linux/bash environment.

The strategy is to:
1.  Document the Windows-native development environment setup.
2.  Adapt the build and run scripts to be platform-aware or provide Windows-specific alternatives.
3.  Ensure a consistent and simple developer experience across all platforms.

## 2. Environment Setup

The `scripts/setup.sh` script is not compatible with Windows. The purpose of the script is to verify that all necessary dependencies are installed. On Windows, `flutter doctor` serves a similar purpose.

### Windows Dependencies

A developer on Windows will need:

1.  **Flutter SDK:** The core requirement.
2.  **Visual Studio "Desktop development with C++" workload:** This provides the C++ compiler (MSVC), CMake, and Ninja, which are required for building the Flutter Windows runner.

The `flutter doctor` command will validate that these dependencies are correctly installed.

## 3. Build & Run Process

The existing `Makefile` is not directly runnable on a standard Windows machine without a compatibility layer like WSL or Git Bash, due to the `SHELL := /bin/bash` directive and the use of bash-specific commands.

### Recommended Approach: `flutter` commands

The most straightforward and platform-idiomatic way to work with Flutter on Windows is to use the `flutter` command directly in a terminal like PowerShell or Command Prompt.

*   **Run the app:**
    ```powershell
    cd app
    flutter run -d windows
    ```

*   **Build the app:**
    ```powershell
    cd app
    flutter build windows --release
    ```

*   **Run tests:**
    ```powershell
    cd app
    flutter test
    ```

*   **Create Distribution (Release):**
    ```powershell
    cd app
    flutter build windows --release
    cd ..
    New-Item -ItemType Directory -Force -Path dist
    Copy-Item -Recurse -Force app\build\windows\x64\runner\Release\* dist\
    ```

### `Makefile` Adaptations

To maintain a unified `make` interface for developers who prefer it, we can make the following changes to the `Makefile`:

1.  **Detect the Operating System:** Use `ifeq` to detect the OS and set commands accordingly.
2.  **Create Windows-specific targets or logic:**

```makefile
# At the top of the Makefile
ifeq ($(OS),Windows_NT)
    RUN_COMMAND = $(FLUTTER) run -d windows
    TEST_COMMAND = $(FLUTTER) test integration_test/ -d windows
else
    RUN_COMMAND = PATH="$(LLVM_BIN):$$PATH" GDK_BACKEND=x11 XAUTHORITY=$$(ls /run/user/$$(id -u)/.mutter-Xwaylandauth.* 2>/dev/null | head -1) $(FLUTTER) run -d linux
    TEST_COMMAND = PATH="$(LLVM_BIN):$$PATH" GDK_BACKEND=x11 XAUTHORITY=$$(ls /run/user/$$(id -u)/.mutter-Xwaylandauth.* 2>/dev/null | head -1) $(FLUTTER) test integration_test/ -d linux
endif

# ...

.PHONY: run
run: $(PUB_STAMP)
	cd $(APP_DIR) && $(RUN_COMMAND)

# ...

.PHONY: integration-test
integration-test: $(PUB_STAMP)
	cd $(APP_DIR) && $(TEST_COMMAND)

```

This approach is more robust but requires more significant changes to the `Makefile`. A simpler short-term solution is to add a separate `run-windows` target.

## 4. Proposed Implementation Steps

1.  **Create `docs/WINDOWS_BUILD_STRATEGY.md`:** (This document).
2.  **Update `README.md` or create a `CONTRIBUTING.md`:** Add a section for Windows development, detailing the setup and build commands.
3.  **(Optional) Modify `Makefile`:** Implement one of the strategies above to make the `Makefile` more platform-agnostic or add Windows-specific targets. For example, add `run-windows`, `test-windows`, etc.
4.  **Remove `setup.sh` dependency:** Ensure that documentation emphasizes `flutter doctor` for dependency checking on all platforms, and clarify that `setup.sh` is for Linux only.

By following this strategy, we can support Windows development with minimal disruption and maintain a clear and accessible process for all contributors.
