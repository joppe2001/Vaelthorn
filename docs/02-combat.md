# 02 — Combat

The single most important system. Get this right and the rest builds on solid ground.

## Stats (per unit)

| Stat | Type | Default range | Notes |
|---|---|---|---|
| `MAX_HP` | int | 500 – 50000 | Scales hard with level + rarity |
| `HP` | int | 0 – MAX_HP | Current health |
| `ATK` | int | 50 – 5000 | Drives damage output |
| `DEF` | int | 30 – 3000 | Reduces incoming damage |
| `SPD` | int | 80 – 200 | Drives turn order |
| `CRIT_RATE` | float | 0.05 – 1.0 | Chance to crit (5% base) |
| `CRIT_DMG` | float | 1.5 – 3.5 | Crit multiplier (150% base) |
| `ACC` | float | 0.85 – 1.0 | Hit chance modifier |
| `EVA` | float | 0.0 – 0.5 | Dodge chance |
| `LUK` | int | 0 – 1000 | Drives rare procs and loot |
| `RES` | float | 0.0 – 0.8 | Reduces status effect duration/chance |
| `ELEMENT` | enum | one of 6 | Fire / Water / Earth / Wind / Light / Dark |
| `CLASS` | enum | one of 6 | Attacker / Defender / Healer / Buffer / Debuffer / Ranger |

## Damage formula

```text
base       = max(1, (skill_power * attacker.ATK) - target.DEF * 0.5)
elemental  = element_table[attacker.ELEMENT][target.ELEMENT]   # 0.5, 1.0, 1.5, or 2.0
variance   = random_uniform(0.95, 1.05)
crit_roll  = random() < attacker.CRIT_RATE
crit_mult  = attacker.CRIT_DMG if crit_roll else 1.0
luk_proc   = random() < (attacker.LUK / 1000.0)   # rare 'lucky strike'
luk_mult   = 1.5 if luk_proc else 1.0

damage = floor(base * elemental * variance * crit_mult * luk_mult)
```

**Design notes:**

- `skill_power` is a per-skill multiplier (basic attack = 1.0, big skills = 2.5–4.0).
- The `DEF * 0.5` term keeps tanks meaningful without making them invincible.
  Tune the `0.5` constant later — it's the main knob for defense feel.
- `variance` adds tiny noise so damage numbers aren't identical. Players notice.
- Crit and Luck multiply independently. A crit + lucky strike feels *huge*.

## Hit / dodge

```text
hit_chance = clamp(attacker.ACC - target.EVA, 0.05, 1.0)
hit        = random() < hit_chance
```

- Floor of 5% means a fully-evasive enemy still gets hit sometimes (avoids
  feel-bad infinite-miss loops).
- Ceiling of 100% means high-accuracy attackers always land — Acc is meaningful.

## Turn order (ATB)

A speed-tick ATB system. Smooth, readable, classic.

```text
on each engine tick (60 ticks/sec):
    for unit in alive_units:
        unit.atb += unit.SPD * delta_time
        if unit.atb >= 100:
            queue_turn(unit)
            unit.atb = max(0, unit.atb - 100)
```

- A unit with SPD 150 fills 50% faster than SPD 100 → roughly 1.5x actions.
- Ultimate / heavy skills can cost more than 100 ATB (e.g. 130) to model recovery.
- Speed buffs/debuffs feel impactful — a 30% SPD debuff is a *real* turn lost.

Alternative: **simple round-based** (sort by SPD, everyone acts once per round).
Cleaner to implement, less expressive. Recommended for Phase 1, upgrade to ATB
in Phase 2.

## Elements

A 4-element wheel + a Light/Dark pair.

```text
Fire   > Wind  (1.5x)
Wind   > Earth (1.5x)
Earth  > Water (1.5x)
Water  > Fire  (1.5x)

Light <-> Dark (2.0x both directions)
Same element        : 1.0x
Reverse of advantage: 0.5x   (e.g. Wind hits Fire for 0.5x)
Light/Dark vs elemental: 1.0x (neutral)
```

The `element_table` is a 6x6 lookup. Store it as a constant — never compute at
runtime.

## Status effects

Phase 2 starter set. Each effect has a `duration` (in turns) and an optional `power`.

| Effect | Behavior | Resisted by |
|---|---|---|
| **Burn** | DoT, 5% MAX_HP per turn, fire-flagged | RES |
| **Bleed** | DoT, 3% MAX_HP per turn, physical | RES |
| **Poison** | DoT, scales with target MAX_HP (5–10%) | RES |
| **Stun** | Skip next turn | RES (high resist) |
| **Freeze** | Skip turn; breaks on damage taken | RES |
| **Silence** | Cannot use skills, only basic attack | RES |

Buffs / debuffs (stat modifiers): `ATK_UP`, `ATK_DOWN`, `DEF_UP`, `DEF_DOWN`,
`SPD_UP`, `SPD_DOWN`, `CRIT_UP`, etc. — 3 stages each (e.g. ATK_UP +15% / +30%
/ +50%). Stacking caps at the highest stage.

## Skills

```text
Skill {
    id:          string
    name:        string
    description: string
    icon:        Texture
    cost:        int           # ATB cost, or SP if you add an SP system
    cooldown:    int           # turns; 0 = no CD
    target_type: enum          # ENEMY_SINGLE | ENEMY_ALL | ALLY_SINGLE | ALLY_ALL | SELF
    power:       float         # damage multiplier
    hits:        int           # number of damage instances
    element:     Element | INHERIT
    effects:     Array<StatusEffect>
    animation:   string        # anim key
    sfx:         string        # sfx key
}
```

**Hero skill kit** (typical):

- 1x basic attack (power 1.0, no cooldown, free)
- 2x active skills (power 1.8–2.5, 2–4 turn cooldown, may apply status)
- 1x **Ultimate** (power 3.5–5.0, charges via taking/dealing damage, single-use until recharged)
- 1x **Passive** (always on, e.g. "+10% crit when below 50% HP")

## Ultimate gauge

Inspired by BF's BB system. Each hero has a 0–100 gauge.

```text
on dealing damage:   gain   = 8 * (damage / target.MAX_HP) * 100
on taking damage:    gain   = 12 * (damage / self.MAX_HP) * 100
on basic attack:     +5
on killing blow:     +15
```

Tune these numbers in playtesting. The gauge should fill in **~5–7 turns** of
normal play.

## AI for enemies

Phase 2 baseline:

1. If any hero is below 30% HP → use highest-damage available skill on them.
2. If ultimate is ready → use it.
3. If a skill is off cooldown → use it (prefer matching element advantage).
4. Otherwise → basic attack the lowest-HP target.

This is naive but feels deliberate. Upgrade with role-specific scripts later
(healer enemies prioritize allies, debuffers spread DoTs, etc.).

## RNG and determinism

- Combat RNG is **seeded per battle** with a deterministic seed.
  Useful for: replays, bug reports, save-mid-fight, test reproducibility.
- Gacha RNG is **always live** (never seeded). Drift-proof.
- Persist the battle seed in the save file mid-fight.

## Testing the combat core

Write these tests *before* polishing UI:

- Damage formula: known inputs → known output (within variance range).
- Element table: 36 cells covered.
- Hit chance floor/ceiling.
- ATB ordering: SPD 150 acts before SPD 100 within a fixed time window.
- Status: burn ticks 5 times over 5 turns then expires.
- Ultimate gauge fills at expected rate over scripted combat.

If these tests pass, the rest of the game is decoration. If they don't, no
amount of polish saves you.
