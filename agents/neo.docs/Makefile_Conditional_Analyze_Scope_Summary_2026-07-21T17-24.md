# Makefile Conditional Analyze Scope Fix — 2026-07-21 17:24

## Outcome

Fixed the Makefile analyzer entry points after the deliberate deletion of
`app/integration_test`. The directory remains deleted.

## Implementation

- Added shared `ANALYZE_DIRS`, always initialized to `lib test`.
- Conditionally appends `integration_test` only when
  `app/integration_test` exists.
- Applied the shared scope to `analyze`, `lint-style`, and the analyzer step in
  `win-test`, per Oracle's portability/consistency review.

## Verification

`make lint-style V=-vv` passed. The executed analyzer command was:

`flutter analyze --fatal-warnings lib test`

Flutter reported `No issues found!`.

The first sandboxed attempt could not update Flutter's SDK cache outside the
workspace; the approved rerun completed successfully. No Dart source or lunar
transition changes were altered by this follow-up.
