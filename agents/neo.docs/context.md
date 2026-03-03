# Neo Context

## Sprint 5: Refinement — 2026-03-02
- Implemented `ExpansionLogic` (pure logic) in `app/lib/features/timeline/expansion_logic.dart`.
- TDD complete: `app/test/features/timeline/expansion_logic_test.dart` passes with 9 tests.
- Logic covers: Settings overrides, Interaction Zone (dy >= stripHeight), Hit Zone (event bounds), and Default (collapsed).
