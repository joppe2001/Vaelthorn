# 11 — Engineering Principles

The disciplines that keep this project healthy as it grows. This doc is the
**guard rails** — every code change should pass the rules here.

Read this once, then come back when a decision feels hard. If you're tempted
to break a rule here, the right move is usually to stop and reconsider.

---

## The promise

By the end of Phase 8, adding a **brand new hero** with unique skills should
cost ~30 minutes. By the end of Phase 14, it should still cost ~30 minutes.

This document is the reason that promise is achievable.

---

## Architecture principles

### 1. Data-driven everything

No hardcoded heroes, weapons, skills, items, stages, or enemies. Everything
content is a **Godot Resource (`.tres`)** edited in the inspector.

**Test:** can you add a new hero by duplicating an existing `.tres` file and
changing fields? If yes, the system is healthy. If you have to touch a `.gd`
file, the architecture has rotted.

| Content type | Resource class | Code change to add a new one? |
|---|---|---|
| Hero | `HeroData` | No |
| Skill | `SkillData` | No (uses Effect composition) |
| Weapon | `WeaponData` | No |
| Enemy | `EnemyData` | No |
| Stage | `StageData` | No |
| Item | `ItemData` | No |
| Status effect | `StatusEffectData` | Sometimes (when adding a novel mechanic) |
| Element | `Element` enum | Yes (rare — only when adding a 7th element) |

The only time adding content costs code is when you're introducing a
**fundamentally new mechanic**. Even then, it costs code *once*, then becomes
data forever.

### 2. Composable Effects (the killer pattern)

This is the single most important architectural decision in the project.

**Don't write a new class per skill.** Write a small library of *Effect atoms*,
and compose skills from them.

```gdscript
# scripts/combat/effects/effect.gd  — base class
class_name Effect extends Resource

enum Trigger { ON_USE, ON_HIT, ON_TURN_START, ON_TURN_END, ON_KILL, ON_DAMAGED }
@export var trigger: Trigger = Trigger.ON_USE

func apply(ctx: EffectContext) -> void:
    push_error("Effect.apply() must be overridden")
```

```gdscript
# scripts/combat/effects/effect_damage.gd
class_name EffectDamage extends Effect

@export var power_mult: float = 1.0
@export var hits: int = 1
@export var element_override: int = -1

func apply(ctx: EffectContext) -> void:
    for _i in hits:
        var result := Damage.compute(ctx.attacker_stats, ctx.target_stats,
            power_mult, _resolve_element(ctx), ctx.rng)
        ctx.bus.emit_damage(ctx.target, result)
```

```gdscript
# scripts/combat/effects/effect_status.gd
class_name EffectStatus extends Effect

@export var status_id: String
@export var duration: int = 2
@export var chance: float = 1.0
@export var power: float = 0.0

func apply(ctx: EffectContext) -> void:
    if ctx.rng.chance(chance * (1.0 - ctx.target.stats.res)):
        ctx.target.add_status(status_id, duration, power)
```

```gdscript
# scripts/combat/effects/effect_heal.gd
class_name EffectHeal extends Effect
@export var heal_mult: float = 1.0
func apply(ctx: EffectContext) -> void:
    ctx.target.heal(int(ctx.attacker.stats.atk * heal_mult))
```

A skill is then just a list of effects:

```text
flame_slash.tres:
  name: "Flame Slash"
  target_type: ENEMY_SINGLE
  element: FIRE
  effects:
    - EffectDamage { power_mult: 2.5, element_override: FIRE }
    - EffectStatus { status_id: "burn", duration: 3, chance: 0.6 }
```

A skill that deals damage + burns + heals the caster?

```text
pyromaniac_strike.tres:
  effects:
    - EffectDamage { power_mult: 2.0 }
    - EffectStatus { status_id: "burn", duration: 3, chance: 0.6 }
    - EffectHeal   { heal_mult: 0.2 }   # heals attacker by 20% of their ATK
```

**Zero new code.**

Aim for ~15–25 Effect atoms covering 95% of skill design space. When you find
yourself wanting a 16th skill that needs a new atom, write one new atom —
then it's available to every future skill forever.

This pattern is how Diablo, Magic: The Gathering, Hearthstone, and every real
RPG/CCG engine scales. We do it from day 1.

### 3. Pure-function core

The combat math is pure: `Damage.compute(attacker, target, skill, rng) → result`.
No node references, no signals, no engine globals.

This means:

- Trivially unit-testable.
- Server-portable (rewrite in TypeScript with identical logic, share test vectors).
- Deterministic given the same RNG seed.

Everything in `scripts/combat/` that isn't a Node should be pure. If it needs
to touch the scene tree, it lives in `scenes/battle/` instead.

### 4. Service singletons (Autoloads), not gods

Godot's autoload feature creates global services. Use them — but sparingly,
and with clear responsibilities.

| Autoload | Responsibility | Phase added |
|---|---|---|
| `Game` | Top-level game state, scene transitions | 0 |
| `SaveManager` | Read/write `user://save.json`, handle migrations | 3 |
| `ContentRegistry` | Load all `.tres` files at startup, lookup by ID | 1 |
| `EventBus` | Cross-scene signal hub for loose coupling | 1 |
| `SoundManager` | Play SFX / music by key | 2 |
| `Telemetry` | Track FPS, errors, key events | 2 |
| `Net` | Nakama client wrapper | 9 |

**Anti-pattern:** a `God.gd` autoload that knows about everything. If a new
responsibility doesn't fit any existing service, add a new service — don't
expand an existing one past its name.

### 5. Signals over polling

Game state changes emit signals. Other systems subscribe. No `_process` loops
asking "did X happen?"

```gdscript
# Unit emits damage taken
class_name Unit extends Node2D
signal damaged(amount: int, is_crit: bool)

func take_damage(amount: int, is_crit: bool) -> void:
    hp -= amount
    damaged.emit(amount, is_crit)
```

```gdscript
# HP bar listens
unit.damaged.connect(_on_damaged)

# Damage popup listens
unit.damaged.connect(_on_damaged)

# Camera shake listens
unit.damaged.connect(_on_damaged)
```

Each listener does one thing. None of them know about each other. Removing
the popup doesn't affect the HP bar.

### 6. Composition over inheritance

Heroes and enemies are the *same class* (`Unit`) parameterized by `HeroData`
or `EnemyData`. They differ in data, not in class.

Skills, passives, status effects, and items all use composition (the Effect
pattern above), not inheritance.

The only inheritance we use is:

- `Effect → EffectDamage / EffectStatus / EffectHeal / ...`
- `Resource → HeroData / WeaponData / ...` (just for Godot's editor)

If you find yourself writing `EmberKnight extends Hero`, stop. Heroes are
data, not classes.

---

## Content authoring pipeline

The pipeline is what makes adding content cheap. Build the tooling early.

### Hero authoring (target: ≤30 min per hero, excluding sprite work)

1. Duplicate `data/heroes/_template.tres` → rename to `<hero_id>.tres`.
2. Open in Godot inspector. Fill in name, element, class, base stats.
3. Drop a sprite folder into `assets/sprites/heroes/<hero_id>/`.
4. Configure SpriteFrames in editor.
5. Reference 3 existing skills + 1 ultimate from `data/skills/`. (If a new
   skill is needed, author it — see below.)
6. Reference a passive from `data/passives/`. (Same — author if new.)
7. Open the **Sandbox** debug scene, spawn the hero, run a debug battle.
8. Commit.

If step 5/6 requires a new skill or passive, that's another ~10 min. So a
fully novel hero with a custom kit ≈ 60 min. A "stat variant" hero reusing
existing kits ≈ 15 min.

### Skill authoring (target: ≤10 min per skill)

1. Duplicate `data/skills/_template.tres`.
2. Set name, description, icon, target type, cost, cooldown.
3. Open the `effects` array in inspector. Click "+" → pick an Effect type →
   configure exported params.
4. Add as many effects as needed (usually 1–3).
5. Reference an animation key (animations are also authored separately).
6. Save.

### Weapon authoring (target: ≤15 min)

1. Duplicate `data/weapons/_template.tres`.
2. Set name, weapon class (Sword / Staff / ...), base stat ranges.
3. Add a `WeaponPassive` (uses the same Effect system — weapons can compose
   effects too).
4. Reference an icon.
5. Save.

### Stage authoring (target: ≤20 min per stage)

1. Duplicate `data/dungeons/_template_stage.tres`.
2. Set chapter, sub-index, stamina cost, recommended power.
3. Add 1–3 waves; each wave references enemy `.tres` files + count + position.
4. Reference a background and music key.
5. Set drop tables.
6. Save.

### The Sandbox tool (build in Phase 2)

A debug scene accessible from a dev menu (only in debug builds). Lets you:

- Spawn any hero at any tier/star/level instantly.
- Equip any weapon and gear.
- Drop into a 1v1, 5v5, or custom battle against any enemy comp.
- Inspect damage logs in real-time.
- Replay battles deterministically from a seed.

**This tool pays for itself within a week.** Every content QA session takes
30 seconds instead of 10 minutes.

### Content validation (CI gate)

A test that loads *every* `.tres` file under `data/` and verifies:

- All required fields are set.
- All referenced IDs (skill IDs, sprite paths, hero IDs in starter rosters)
  resolve.
- No two heroes have the same ID.
- No skill references a non-existent status effect.
- All skill `power_mult` values are within sane bounds (0.1 – 10.0).

This test runs on every commit. A typo in a `.tres` file breaks the build,
not production.

---

## Testing strategy

### Levels of testing

| Level | What it tests | Tooling | When it runs |
|---|---|---|---|
| **Unit** | Pure functions (damage formula, element table, status math, gacha rates) | gut (Godot Unit Test) | On every save / commit |
| **Integration** | Scripted battle scenarios with known outcomes | gut | On every commit |
| **Content validation** | All `.tres` files load and resolve | gut | On every commit |
| **Performance regression** | Battle scene maintains 60 fps with N units | manual + scripted | At phase end |
| **Save migration** | All historical save versions load into latest code | gut | On every commit after save format changes |
| **Parity (Phase 9+)** | Client GDScript and server TS produce identical results on shared test vectors | jest + gut, shared JSON | On every commit to either client or server |

### Unit test minimums

These tests must exist by the end of each phase that introduces them:

**Phase 1:**
- Damage formula with 20 known input → output pairs.
- Element table: all 36 cells.
- Hit / dodge floor + ceiling.

**Phase 2:**
- ATB ordering with edge cases (tied speeds, speed buffs/debuffs).
- Each Effect atom (Damage, Status, Heal, Buff, Debuff, ...).
- Status effect lifecycle (apply, tick, expire, stack).

**Phase 6:**
- Gacha rates: 100k simulated pulls within 0.5% of design target per tier.
- Pity: 100th pull guarantees Legendary+.
- Soul stone crafting math.

**Phase 9 (server):**
- Test vectors shared between client and server.
- CI runs both test suites against the same vectors.

### Integration test sample

```gdscript
# tests/test_battle_scenarios.gd
func test_burn_kills_low_hp_target():
    var attacker = make_unit({atk = 100, crit_rate = 0.0})
    var target = make_unit({hp = 10, def = 0, res = 0.0})

    var burn = EffectStatus.new()
    burn.status_id = "burn"
    burn.duration = 3
    burn.chance = 1.0

    burn.apply(make_ctx(attacker, target))
    battle.tick_turn(target)

    assert_eq(target.hp, 5, "burn should deal 5 dmg at 5%/turn for 10 max hp")
```

Write these for every "edge case I thought about." Future-you will break them
within months, and the test will catch it.

---

## Performance budgets

These numbers are not aspirations. They're hard limits. If we miss them, we
stop and fix before moving on.

| Metric | Budget | Measured how |
|---|---|---|
| **Frame rate** | 60 fps locked (desktop), 30 fps min (low-end mobile later) | Godot's built-in monitor |
| **Battle scene active nodes** | ≤ 200 | Print scene tree at battle start |
| **Sprite atlas memory** | ≤ 200 MB total at any time | Profiler memory tab |
| **Scene load time (any → battle)** | ≤ 2 seconds | Print timing in `_ready` |
| **Save write time** | ≤ 200 ms | Time around `JSON.stringify + write` |
| **Save read time** | ≤ 300 ms | Time around startup load |
| **Damage popup count** | ≤ 30 simultaneous (pool the rest) | Object pool size |
| **RPC roundtrip (Phase 9+)** | ≤ 300 ms p95 to nearby region | Server-side metrics |
| **Initial download size** | ≤ 200 MB at v1.0 launch | Build artifact size |

### Object pooling

Anything that spawns and dies frequently must be pooled. Specifically:

- Damage popups
- Particle effects
- Floating numbers
- Status icons

Pool of 50 of each, recycled. Never instantiate during combat.

### Atlas everything

Sprites get bundled into texture atlases (`AtlasTexture` in Godot). Reduces
draw calls dramatically. Set up at import time.

### Profile every phase end

At the end of every phase:

1. Open the most complex scene that phase introduced.
2. Run with Godot's profiler.
3. Check FPS, draw calls, memory.
4. Record numbers in `docs/perf-log.md` (we'll add this in Phase 1).

If FPS dropped vs last phase by >5, **stop and investigate before the next phase**.

---

## Save format & migrations

The save format **will** change. Plan for it.

### Every save has a version

```json
{
  "save_version": 7,
  "saved_at": "2026-09-15T14:00:00Z",
  "player": { ... },
  ...
}
```

### Migration functions are append-only

```gdscript
# scripts/runtime/save_migrations.gd

func migrate(save: Dictionary) -> Dictionary:
    while save.save_version < CURRENT_VERSION:
        match save.save_version:
            1: save = _v1_to_v2(save)
            2: save = _v2_to_v3(save)
            3: save = _v3_to_v4(save)
            # ... never delete a migration
    return save

func _v1_to_v2(save: Dictionary) -> Dictionary:
    # added "stamina_last_tick" field
    save.currencies.stamina_last_tick = 0
    save.save_version = 2
    return save
```

**Never delete a migration.** A player who hasn't played in 18 months should
still be able to load their save.

### Test old saves against new code

For every shipped version, commit a sample save to `tests/save_fixtures/`.
The test suite loads each and verifies they migrate cleanly.

### Server migrations (Phase 9+)

Postgres schema migrations live in `server/migrations/NNN_*.sql`. Forward-
only, never edited after they ship. Apply on server start.

---

## Telemetry & observability

You can't fix what you can't see.

### Phase 1–8 (offline)

- Local crash reporter (built-in Godot crash dumps).
- Opt-in anonymous telemetry to a free Sentry tier (or self-hosted GlitchTip).
- Track: app version, crash stack trace, FPS percentiles, scene timings.

### Phase 9+ (server)

- Every RPC logged with: user_id (hashed), timing, outcome.
- Gacha pulls logged with: banner, result, pity counters at time of pull.
- Battle outcomes logged: dungeon, win/loss, turns, time, team composition.
- Currency flow tracked: sources vs sinks per day.
- Daily/weekly/monthly active users.

### Dashboards (Grafana — free, self-hosted)

- Player retention (D1, D7, D30)
- Daily gacha pull distribution
- Battle win rates per dungeon (balance signal)
- Average session length
- RPC error rate
- Server CPU / memory / disk

A weekly review of these dashboards is mandatory once live. Trust data, not
vibes.

---

## Code discipline

### Solo PR workflow

Even working alone:

- Create a branch per feature/phase.
- Push, open a PR to `main` on GitHub.
- **Self-review the diff the next day** with fresh eyes.
- Merge only after self-review + tests pass.

This catches ~80% of "what was I thinking" code before it lands.

### Pre-commit hooks

`.pre-commit-config.yaml` with:

- GDScript formatter (`gdformat` from gdtoolkit).
- GDScript linter (`gdlint`).
- "All `.tres` files validate" content test.
- "Unit tests pass" test.

A bad commit literally cannot land. The build stays green forever.

### CI on GitHub Actions

Every PR runs:

- Lint
- Content validation
- Unit tests
- Integration tests
- Save migration tests
- Performance smoke test (does it boot, does it run a battle?)

Pipeline budget: ≤ 5 minutes. Slow CI = ignored CI.

### Decision log (ADRs)

In `docs/adr/NNN-title.md`, record every architectural decision:

```markdown
# ADR-001: Use Nakama for backend

## Context
Need a game server for Phase 9+. ...

## Decision
Nakama, self-hosted, with TypeScript runtime.

## Alternatives considered
- PlayFab (rejected: per-MAU pricing, vendor lock-in)
- Custom Node.js server (rejected: 6mo of scaffolding work)
- Firebase + Cloud Functions (rejected: cost at scale, glue code)

## Consequences
- Need to learn Nakama's APIs.
- VPS hosting required (~$25/mo).
- Server logic in TypeScript, different from client GDScript.
- Owns our data; can self-host forever.
```

Future-you (or contributors) thank past-you. Write these for **every choice
that took more than 15 minutes to decide**.

---

## Phase-end gates

A phase isn't done until **all gates pass**. No exceptions.

### Universal gates (every phase)

- [ ] All unit + integration tests pass.
- [ ] Content validation passes (no broken `.tres` references).
- [ ] FPS budget held (60 fps in the heaviest new scene).
- [ ] No new warnings in editor / debugger.
- [ ] Save migration tested if save format changed.
- [ ] Self-review of full PR diff completed.
- [ ] Decision log updated for any new architectural choices.

### Phase-specific gates

| Phase | Gate |
|---|---|
| 1 | Damage formula matches test vectors to the integer. |
| 2 | Sandbox tool exists and works. ATB ordering tested. |
| 3 | Save round-trip is loss-less for all 10 heroes. |
| 4 | All 8 chapter-1 stages clearable with starter heroes. |
| 5 | Promotion ladder fully testable end-to-end (Common → Mythic on a test save). |
| 6 | Gacha rates within 0.5% of design over 100k simulated pulls. |
| 7 | Refinement R5 reachable from R1 via dupes in dev tools. |
| 8 | **Three external playtesters complete the v1.0 tutorial without help.** |
| 9 | Server-resolved combat matches client expectations on shared vectors. |
| 10 | Arena matchmaking returns matched-rank opponents in < 500ms p95. |
| 11 | Guild chat handles 30 concurrent users without dropped messages. |
| 12 | Raid contribution math correct under concurrent attempts. |
| 13 | 3-player co-op survives 1 disconnect + reconnect without state loss. |

---

## Refactor checkpoints

After every 3 phases, the next phase is a **consolidation phase** — no new
features, only cleanup.

| Checkpoint | After | Focus |
|---|---|---|
| **C1** | Phase 3 | Battle scene refactor: extract managers, finalize signal contracts |
| **C2** | Phase 7 | Content pipeline polish: tooling, validation, sandbox upgrades |
| **C3** | Phase 10 | Server boundary hardening: error handling, retry, offline grace |
| **C4** | Phase 13 | Live ops tooling: admin panel, content cadence templates |

Checkpoints aren't optional. Skipping one means accumulating debt that
compounds.

---

## Stop conditions

Stop the project and consolidate when **any** of these is true:

- A test has been red for more than 24 hours.
- FPS dropped > 5 between phases.
- Content authoring takes > 2× target time on 3 consecutive additions.
- A save migration was needed but skipped ("we'll fix it later").
- More than 5 TODO/FIXME comments accumulated in a single file.
- You haven't reviewed your own diff in over a week.

Stopping is engineering. Pushing through is debt.

---

## What I commit to (as your collaborator)

When we work together in future sessions, I will:

1. **Always propose data-driven solutions before code-driven ones.** If a
   feature can be a `.tres` field, it will be.
2. **Always favor Effect composition over new classes.** New skills are data
   first. New mechanics get a new Effect atom only when nothing existing
   composes.
3. **Always write tests with combat logic.** If we change a formula, the
   test changes first (TDD).
4. **Always check performance budget.** Before merging anything that touches
   the battle scene, we measure FPS.
5. **Always write a save migration** when changing save shape. No exceptions.
6. **Always log a decision in ADR** for choices that took real thought.
7. **Always update this doc** when our principles evolve.

If I ever propose something that violates these — call me out. Treat this
doc as the contract.
