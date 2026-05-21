# 07 — Tech

How the project is structured, what Godot patterns to use, and how the data
flows.

## Stack

| Layer | Choice | Why |
|---|---|---|
| **Engine** | Godot 4.3+ (LTS) | Free, open source, killer 2D pipeline, exports everywhere |
| **Language** | GDScript | Fast iteration, fine for this scope; tightly integrated |
| **Optional 2nd lang** | C# | Drop to it only if profiling identifies a hot path |
| **Pixel-art editor** | Aseprite ($20) | Industry standard, palette-aware |
| **Version control** | Git + GitHub (private repo) | Standard |
| **Data files** | `.tres` Godot Resources | Designer-editable in the editor |
| **Save format** | JSON, versioned | Human-readable, debuggable |
| **Sound editor** | Audacity (free) | For trimming SFX |
| **Tooling** | None custom in v1 | Use Godot's editor + your text editor |

## Why Godot over Unity

- **Free, no royalties, no licensing surprises.**
- **2D is a first-class citizen** (Unity's 2D is a port from 3D — Godot's is native).
- **GDScript iterates faster than C#** for game logic.
- **Exports to every platform you care about** (Windows, macOS, Linux, iOS, Android, Web).
- **Smaller engine, lighter install, faster startup.**
- **Open source** — if you hit a bug, you can read the engine code.

The one tradeoff: smaller ecosystem of tutorials and asset store. For a 2D
pixel-art turn-based game, this doesn't matter — everything you need exists
in Godot's docs.

## Project structure

```text
pixel-arena/
├── project.godot
├── icon.svg
├── export_presets.cfg
├── .gitignore
├── README.md
├── docs/                              # this design doc lives here
├── assets/
│   ├── sprites/
│   │   ├── heroes/
│   │   │   └── ember_knight/
│   │   │       ├── idle.png
│   │   │       ├── attack.png
│   │   │       ├── hurt.png
│   │   │       └── ...
│   │   ├── enemies/
│   │   ├── effects/
│   │   └── backgrounds/
│   ├── ui/
│   │   ├── panels/
│   │   ├── buttons/
│   │   └── icons/
│   ├── fonts/
│   ├── sfx/
│   ├── music/
│   └── CREDITS.md
├── data/
│   ├── heroes/
│   │   ├── ember_knight.tres
│   │   ├── tideguard.tres
│   │   └── ...
│   ├── skills/
│   │   ├── flame_slash.tres
│   │   └── ...
│   ├── enemies/
│   ├── dungeons/
│   │   └── chapter_1/
│   │       ├── stage_1.tres
│   │       └── ...
│   └── items/
├── scenes/
│   ├── title/
│   │   ├── title.tscn
│   │   └── title.gd
│   ├── hub/
│   ├── hero_roster/
│   ├── hero_detail/
│   ├── party_builder/
│   ├── dungeon_map/
│   ├── stage_select/
│   ├── battle/
│   │   ├── battle.tscn
│   │   ├── battle.gd
│   │   ├── unit.tscn
│   │   ├── unit.gd
│   │   ├── damage_popup.tscn
│   │   └── damage_popup.gd
│   ├── battle_results/
│   ├── summon/
│   └── shared/                       # reusable scenes (buttons, dialogs)
├── scripts/
│   ├── combat/
│   │   ├── damage.gd                 # damage formula (pure functions)
│   │   ├── turn_order.gd             # ATB
│   │   ├── elements.gd               # element table
│   │   ├── status.gd                 # status effects
│   │   └── battle_state.gd           # the battle's runtime model
│   ├── data/
│   │   ├── hero_data.gd              # Resource class
│   │   ├── skill_data.gd
│   │   ├── enemy_data.gd
│   │   ├── stage_data.gd
│   │   └── save_data.gd
│   ├── runtime/
│   │   ├── player.gd                 # player progression state
│   │   ├── inventory.gd
│   │   ├── currency.gd
│   │   ├── gacha.gd
│   │   └── save_load.gd
│   ├── ui/
│   │   ├── currency_bar.gd
│   │   ├── hero_card.gd
│   │   └── ...
│   └── util/
│       ├── rng.gd                    # seeded RNG wrapper
│       ├── tween_helpers.gd
│       └── ...
└── tests/
    ├── test_damage.gd
    ├── test_elements.gd
    ├── test_turn_order.gd
    └── test_gacha.gd
```

## Core data classes

### HeroData

```gdscript
class_name HeroData extends Resource

@export var id: String
@export var display_name: String
@export var lore: String

@export var element: int                          # Element enum
@export var class_type: int                       # Class enum
@export var base_rarity: int                      # 1-5

# base stats at Lv 1, base rarity
@export var base_hp: int
@export var base_atk: int
@export var base_def: int
@export var base_spd: int
@export var base_crit_rate: float
@export var base_crit_dmg: float
@export var base_acc: float
@export var base_eva: float
@export var base_luk: int
@export var base_res: float

@export var skills: Array[SkillData]
@export var ultimate: SkillData
@export var passive: PassiveData

@export var sprite_set: SpriteFrames              # idle, attack, hurt, ult, victory, defeat
@export var portrait: Texture2D
```

### SkillData

```gdscript
class_name SkillData extends Resource

enum TargetType { ENEMY_SINGLE, ENEMY_ALL, ALLY_SINGLE, ALLY_ALL, SELF }

@export var id: String
@export var skill_name: String
@export var description: String
@export var icon: Texture2D
@export var atb_cost: int = 100
@export var cooldown: int = 0
@export var target_type: TargetType
@export var power: float = 1.0
@export var hits: int = 1
@export var element: int                          # or -1 = INHERIT
@export var effects: Array[StatusEffectData]
@export var animation: String
@export var sfx: String
```

### SaveData (JSON shape)

```json
{
  "save_version": 1,
  "player": {
    "name": "Joppe",
    "level": 42,
    "xp": 12500
  },
  "currencies": {
    "gold": 1250000,
    "gems": 425,
    "stamina": 87,
    "stamina_last_tick_unix": 1750000000,
    "evolution_dust": 145,
    "prismatic_shard": 3
  },
  "heroes": [
    {
      "id": "ember_knight",
      "instance_id": "uuid-v4-here",
      "level": 60,
      "rarity": 4,
      "xp": 12345,
      "soul_stones": 12,
      "gear": {
        "weapon": "gear-uuid-1",
        "armor": null,
        "helmet": null,
        "boots": "gear-uuid-2",
        "accessory": null,
        "relic": null
      }
    }
  ],
  "gear_inventory": [
    {
      "uuid": "gear-uuid-1",
      "slot": "weapon",
      "rarity": "blue",
      "main_stat": { "key": "atk_pct", "value": 0.18 },
      "sub_stats": [
        { "key": "crit_rate", "value": 0.04 }
      ]
    }
  ],
  "gacha": {
    "pity_counter_standard": 47,
    "pity_counter_featured": 12
  },
  "dungeon_progress": {
    "chapter_1": { "max_stage": 8, "stars": [3, 3, 3, 3, 3, 3, 3, 3] },
    "chapter_2": { "max_stage": 5, "stars": [3, 3, 3, 2, 1] }
  },
  "quests_daily": { ... },
  "settings": {
    "master_vol": 0.8,
    "music_vol": 0.7,
    "sfx_vol": 1.0,
    "battle_speed": 1.0,
    "skip_animations": false,
    "language": "en"
  }
}
```

Save to `user://save.json`. Always write to a temp file first, then atomic
rename — never half-write a save.

## RNG

A seeded wrapper around `RandomNumberGenerator`. One instance per "domain"
(combat, gacha, gear-rolls). Never share.

```gdscript
class_name SeededRNG extends RefCounted

var rng := RandomNumberGenerator.new()

func _init(seed: int) -> void:
    rng.seed = seed

func chance(p: float) -> bool:
    return rng.randf() < p

func range_float(a: float, b: float) -> float:
    return rng.randf_range(a, b)

func pick(arr: Array):
    return arr[rng.randi() % arr.size()]
```

Combat instantiates a fresh `SeededRNG` per battle, seeded with a deterministic
value (battle id + turn count). Save the seed mid-battle for crash recovery.

## Architectural patterns

### Resources for data, scenes for behavior

Heroes, skills, stages, items → `.tres` Resources. Edit in the Godot inspector.
Behavior (battle logic, UI controllers) → `.tscn` Scenes + `.gd` scripts.

### Signals over polling

Combat is event-driven. When a unit takes damage, it emits `damaged(amount)`.
The damage popup listens. The HP bar listens. The screen-shake listens. Don't
have one mega-script doing everything.

### Pure-function combat core

The damage formula, element table, hit chance — all pure functions in
`scripts/combat/`. No node references, no signals, just math. Easy to unit-test.

```gdscript
# scripts/combat/damage.gd
class_name Damage

static func compute(
    attacker_stats: Dictionary,
    target_stats: Dictionary,
    skill: SkillData,
    rng: SeededRNG
) -> Dictionary:
    var base = max(1, skill.power * attacker_stats.atk - target_stats.def * 0.5)
    var elemental = Elements.multiplier(attacker_stats.element, target_stats.element)
    var variance = rng.range_float(0.95, 1.05)
    var is_crit = rng.chance(attacker_stats.crit_rate)
    var crit_mult = attacker_stats.crit_dmg if is_crit else 1.0
    var is_lucky = rng.chance(attacker_stats.luk / 1000.0)
    var luk_mult = 1.5 if is_lucky else 1.0
    var dmg = int(base * elemental * variance * crit_mult * luk_mult)
    return {
        "damage": dmg,
        "is_crit": is_crit,
        "is_lucky": is_lucky,
        "elemental": elemental
    }
```

This kind of function lives in a static class, has no engine dependencies, and
is testable in isolation.

### Battle state machine

The battle scene is a state machine with these states:

```text
SETUP -> PARTY_INTRO -> AWAITING_INPUT -> RESOLVE_TURN -> CHECK_END -> ...
                                                          -> VICTORY / DEFEAT
```

Each state knows what transitions it allows. Centralized in `battle_state.gd`.
Prevents the classic "I tapped a skill mid-animation and the game broke" bug.

## Performance budget

Honestly, for a turn-based pixel-art game on desktop, performance is not a
concern. But a few rules to keep it that way:

- No `_process` loops doing physics work — turn-based means most things sleep.
- Use `_physics_process` only for the ATB tick (or even better, a `Timer` node).
- Object pool damage popups and particle effects.
- Cap to 60 FPS, don't chase higher refresh rates.

## Testing

Godot 4 ships with `gut` (Godot Unit Test) via the asset library — install it.

What to test (priority order):

1. **Damage formula** — known inputs → known outputs (within variance bound).
2. **Element table** — all 36 cells return expected multipliers.
3. **Turn order** — sorted by SPD, edge cases (tie-breakers).
4. **Status effects** — burn ticks correctly, expires, stacks.
5. **Gacha rates** — over 100k pulls, rates within 0.5% of design target.
6. **Save / load roundtrip** — serialize, deserialize, deep-equal.

Run tests in CI on every push. Set up GitHub Actions with the Godot CLI for
this — there's a maintained action `firebelley/godot-export` and similar.

## Source control

`.gitignore`:

```gitignore
.godot/
.import/
*.translation
export_presets.cfg            # local export paths
.DS_Store
*.swp
user://                       # user save data
```

Commit `.tres` and `.tscn` as text — they merge surprisingly well.
Commit `.png` sprites; never compress them in-repo (it's lossless already).

## Cross-platform exports

Godot's export system handles this — set up presets for each target:

| Target | Notes |
|---|---|
| Windows | Standalone `.exe`, embed PCK |
| macOS | `.app` bundle, must be signed for distribution (signing is a Phase 9 problem) |
| Linux | `.x86_64` binary or AppImage |
| Web | HTML5 export — bigger file, slower load, but instant-share |
| Android | Requires JDK + Android SDK setup |
| iOS | Requires Xcode + Apple Developer account |

For v1, ship **Windows + macOS + Linux**. Mobile is a separate effort.
