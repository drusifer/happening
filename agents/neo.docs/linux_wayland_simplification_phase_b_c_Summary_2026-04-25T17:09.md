# Linux Wayland Simplification Phase B/C Summary - 2026-04-25T17:09

## Scope
Implemented native Linux reservation removal and product/docs alignment.

## Changes
- Removed X11 strut/DOCK setup from `app/linux/runner/my_application.cc`.
- Removed optional Wayland `gtk-layer-shell` setup from the Linux runner.
- Removed C++ settings parsing for reserved strip height.
- Removed direct Happening-owned X11 runner linkage from `app/linux/runner/CMakeLists.txt`.
- Updated docs to reflect Linux non-reserving behavior and validation-gated transparent support.

## Validation
- `make format` passed.
- `make test` passed: 293/293.
- `make build-linux` passed.
- `make analyze` failed due the known Flutter analysis server crash.
