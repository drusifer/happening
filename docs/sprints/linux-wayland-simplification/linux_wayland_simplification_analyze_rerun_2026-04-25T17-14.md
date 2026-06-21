# Linux Wayland Simplification Analyze Rerun - 2026-04-25T17:14

## Trigger
User reran the blocked verification command and asked QA to inspect `build/build.out`.

## Finding
`build/build.out` is from `make analyze` at 2026-04-25 17:14 and still fails in the Flutter analysis server before source diagnostics are produced.

Key failure signatures:
- `OS Error: Too many open files, errno = 24`
- `NativeWatch` / `WatchTree` during analysis root setup
- `Bad state: Future already completed`
- `analysis server exited with code 255`

## QA Result
The Phase D analyzer blocker is unchanged. This is still a Flutter analysis server watcher/file-descriptor failure, not evidence of a Dart or project source diagnostic.

## Remaining Blockers
- Resolve or work around the analyzer watcher/file-descriptor crash so `make analyze` can complete.
- Execute both X11/XWayland and Wayland real-session smoke checks before exposing or claiming Linux transparent support.
