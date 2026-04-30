# Linux Transparent X11 Smoke Flag - 2026-04-25T19:33

## Change
Added a temporary Linux transparent-mode smoke flag for X11/XWayland:

```bash
make run-linux LINUX_TRANSPARENT=1
```

The flag sets `HAPPENING_LINUX_TRANSPARENT=1` while preserving `GDK_BACKEND=x11`.

## Implementation
- `Makefile`: added `LINUX_TRANSPARENT ?= 0` and passes it to `run-linux`.
- `main.dart`: parses `HAPPENING_LINUX_TRANSPARENT` from environment or Dart define.
- `WindowService`: receives transparent pass-through support override when the flag is enabled.
- `HappeningApp` and `TimelineStrip`: thread Linux transparent capability to effective-mode and settings UI.
- `SettingsPanel`: already supports the capability flag; this change wires it into the app path.

## Validation
- `make format`: pass.
- `make test`: pass 293/293.
- `make build-linux`: pass.

## Opaque Layer Follow-Up
Initial user smoke showed the GTK/Flutter window was transparent for a split second, then filled white. The likely culprit was `TimelineStrip` painting a full-window background container plus `BackgroundLayer` in idle transparent mode.

Fix applied:
- idle transparent mode now uses `Colors.transparent` for `painterBackgroundColor`.
- the full-window backing `Container` also stays transparent while idle transparent.

Revalidation:
- `make format`: pass.
- `make test`: pass 293/293.
- clean sequential `make build-linux`: pass.

## Interaction Follow-Up
User clarified transparent mode should keep countdown and controls largely opaque. The prior hidden-control model was wrong for the desired product behavior.

Findings:
- `window_manager.setIgnoreMouseEvents` throws `MissingPluginException` on Linux, so Linux click-through is not available through current Dart/plugin APIs.
- Ctrl+Shift+Space hotkey registration failed on Linux (`Binding '<Primary><Shift>KP_Space' failed`), so Linux smoke now uses Ctrl+Shift+H.

Fixes:
- countdown/buttons remain visible in idle transparent mode.
- Linux transparent smoke remains interactive because click-through is unavailable.
- Linux `setIgnoreMouseEvents` calls are guarded so they do not spam unhandled exceptions.

Revalidation:
- `make format`: pass.
- `make test`: pass 294/294.
- clean `make build-linux`: pass.

## Smoke Instructions
Run `make run-linux LINUX_TRANSPARENT=1`, select "Let clicks pass through" in settings, then test visual transparency and hover expansion. Do not expect click-through on Linux without native/plugin support beyond `window_manager`.
