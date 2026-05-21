# scripts/

All non-scene code. Organized by concern, not by file type.

| Folder | Contents |
|---|---|
| `runtime/` | Autoload singletons (Game, EventBus, ContentRegistry, SaveManager, SoundManager, Telemetry) |
| `combat/` | Pure-function combat core: damage formula, elements, status, Effect atoms (Phase 1+) |
| `data/` | Resource class definitions (HeroData, SkillData, WeaponData, ...) (Phase 1+) |
| `ui/` | Reusable UI controllers (hero card, currency bar, ...) (Phase 2+) |
| `util/` | Cross-cutting helpers: enums, seeded RNG, tween helpers |

## Rules

- **Pure functions** in `combat/`. No node references; no signals; no engine globals.
  Server-portable. Trivially testable.
- **Resource classes** in `data/` are pure data shapes with no behavior.
- **Autoloads** in `runtime/` are the only globals. Add a new one only when a
  responsibility doesn't fit any existing service.
- **Effect atoms** in `combat/effects/` follow the composable pattern from
  [11 — Engineering](../docs/11-engineering.md#2-composable-effects-the-killer-pattern).
