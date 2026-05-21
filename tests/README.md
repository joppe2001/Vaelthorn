# tests/

Test suite. Uses [gut](https://github.com/bitwes/Gut) (Godot Unit Test),
installed via the Asset Library in Phase 1.

| File pattern | Purpose |
|---|---|
| `test_<system>.gd` | Unit tests on pure functions (damage, elements, gacha, ...) |
| `test_scenario_<name>.gd` | Integration tests on scripted battle scenarios |
| `test_content_validation.gd` | Loads every `.tres` and verifies references resolve |
| `test_save_migration.gd` | Roundtrips historical save fixtures through latest code |
| `save_fixtures/` | One sample save per shipped version, for migration testing |
| `vectors/` | Shared JSON test vectors (Phase 9+ for client/server parity) |

## Discipline

- Tests for the combat formula are written **before** changing the formula
  (TDD). Red → Green → Refactor.
- Content validation runs on every commit via pre-commit hook.
- No phase exits until its test gates pass (see
  [11 — Engineering, Phase-end gates](../docs/11-engineering.md#phase-end-gates)).
