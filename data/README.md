# data/

All content lives here as Godot `.tres` Resource files. Designer-editable
via the inspector. **No code per content item.**

| Folder | Contents | Phase |
|---|---|---|
| `heroes/` | One `.tres` per hero | 3 |
| `skills/` | One `.tres` per skill | 2 |
| `weapons/` | One `.tres` per weapon | 7 |
| `enemies/` | One `.tres` per enemy template | 1 |
| `items/` | Materials, consumables | 5 |
| `dungeons/<chapter>/` | One `.tres` per stage | 4 |

## Naming convention

- File: `<snake_case_id>.tres` (matches the resource's `id` field).
- Templates: prefix with `_` (e.g. `_template_hero.tres`). Skipped at load.

## Authoring workflow

See [11 — Engineering](../docs/11-engineering.md#content-authoring-pipeline).
Target: ≤30 min per hero, ≤10 min per skill, ≤20 min per stage.

## Validation

The CI content-validation test loads every `.tres` here and verifies:

- Required fields are set.
- All referenced IDs (skills, items, sprites) resolve.
- No duplicate IDs across the same content type.
- Stat values within designed bounds.

Don't commit a `.tres` that fails validation. Fix it locally first.
