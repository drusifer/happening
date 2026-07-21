# Makefile analyze/lint scope after integration-test removal

## Answer

Yes. The intended contract is:

- Always analyze `app/lib` and `app/test`.
- Add `app/integration_test` only when that directory exists.
- Apply the same source-root selection to `make analyze`, `make lint-style`, and the analyzer step
  in `make win-test`, so platform wrappers do not silently diverge.

## Evidence

- The user stated the contract directly on 2026-07-21: preserve `lib/test`, include
  `integration_test` only when present (`agents/CHAT.md:1082-1083`).
- The present Makefile hard-codes all three roots in `win-test`, both OS branches of `analyze`, and
  `lint-style` (`Makefile:95-99,187-197`). With no `app/integration_test` directory, Flutter exits on
  that missing path before producing analyzer results for the required roots.
- The integration harness was deliberately deleted, not accidentally displaced. The lint-fix record
  says it had no `main`, was unused since Sprint 4, and was deleted with explicit approval
  (`agents/neo.docs/PreExistingLints_Fix_2026-07-08.md:21-38,59-70`).
- Before deletion, the documented full lint-style scope was `lib test integration_test`
  (`agents/neo.docs/PreExistingLints_Fix_2026-07-08.md:21-25`). This establishes that
  `integration_test` was a real source root while present; deletion changes its availability, not
  the permanent `lib/test` baseline.
- Project QA history routinely records `flutter analyze lib/ test/` as the clean analyzer signal
  (`docs/sprints/macos-aswebauth-oauth/macos_aswebauth_phase_c_uat_2026-07-01.md:18-28`).
- Project standards define `make lint` as the full quality gate and `make analyze`/`make lint-style`
  as analyzer checks (`agents/skills/linter/SKILL.md:20-35`; `agents/neo.docs/SKILL.md:140-147`).
  Therefore a removed optional tree must not make those gates structurally unrunnable.

## Conclusion

This is a Makefile scope-discovery defect, not a reason to weaken lint coverage. The durable rule is
mandatory `lib test` plus conditional `integration_test`. If integration tests are restored later,
they automatically re-enter analyzer coverage.
