# 04 — Progression

Currencies, dungeons, gacha (heroes + weapons), gear, and the loops that hold
them together.

## Currencies

| Currency | Earned | Spent on | Cap |
|---|---|---|---|
| **Gold** | Battles, sell drops | Leveling, ascension, gear reforge, promotion | 999,999,999 |
| **Gems** | Daily login, achievements, rare drops | Hero summons, weapon summons, stamina refills | 99,999 |
| **Soul Stones** (per hero) | Dupe conversion, soul shop | Craft heroes | 9,999 each |
| **Weapon Shards** (per weapon) | Dupe conversion | Craft weapons | 9,999 each |
| **Stamina** | Time (1 per 6 min, cap 120+) + items | Running stages | 200+ |
| **Common Dust → Mythic Dust** | Element-specific daily | Ascension within tier | 999 each |
| **Promotion Stones** | Promotion dungeons, achievements | Tier promotion | 9,999 |
| **Phoenix Feather** | Co-op raid endgame, guild boss | Legendary→Mythic promotion | 99 |
| **Celestial Essence** | Co-op raid endgame, season rewards | Mythic Awakening | 99 |
| **Guild Coins** | Guild contribution (Phase 11+) | Guild shop | 99,999 |
| **Arena Honor** | Arena wins (Phase 10+) | Arena shop | 99,999 |
| **Friendship Points** | Friend list, login | Friend summon | 99,999 |

**Design rule:** every currency must have ≥2 sinks and ≥2 sources. Otherwise
players hoard or starve.

## Stamina

A soft session gate. Each stage costs 6–30 stamina.

- Regen: 1 stamina / 6 minutes, capped at max.
- Max grows with player level: `100 + (player_level * 2)`.
- Premium refill: 50 gems for full refill (limit 3/day).

## Dungeons

| Dungeon type | Unlocks | Format | Reward |
|---|---|---|---|
| **Story** | Phase 4 | 10 chapters, 8 stages each | Main XP / gold / first-clear gems |
| **Daily Gold** | Phase 4 | One stage, rotates element | Gold |
| **Daily XP** | Phase 4 | One stage, rotates element | XP potions |
| **Daily Gear** | Phase 7 | One stage, rotates slot | Gear |
| **Daily Dust** | Phase 5 | Rotates element + tier | Ascension dust |
| **Promotion Dungeon** | Phase 5 | Weekly, harder | Promotion stones |
| **Elemental Trial** | Phase 5 | Weekly, restricted element | Soul stones |
| **Tower** | Phase 6 | Endless climb, scaling difficulty | Tower coins (tower shop) |
| **Arena** | Phase 10 | Async PvP — see [09](09-multiplayer.md) | Arena honor |
| **Guild Boss Raid** | Phase 12 | Weekly, persistent guild boss | Phoenix Feathers + raid gear |
| **Co-op Boss Raid** | Phase 13 | 3-player real-time | Celestial Essence + endgame gear |
| **Event Dungeons** | Phase 14+ | Time-limited, themed | Event-exclusive heroes / weapons |

**Stage anatomy:**

```text
Stage {
    id:            string
    name:          string
    chapter:       int
    sub_index:     int
    stamina_cost:  int
    enemy_waves:   Array<Wave>          # 1-3 waves
    background:    Texture
    music:         AudioStream
    first_clear:   Array<Reward>
    repeat_drops:  Array<DropTable>
    auto_unlock_next: bool
}
```

## Hero gacha (Summoning)

The collection engine. Must feel exciting without feeling extractive.

### Banners

| Banner | Pool | Pity | Notes |
|---|---|---|---|
| **Standard** | All non-event heroes | 100 pulls → guaranteed Legendary+ | Always open |
| **Featured** | Same + 50% of Legendary+ rolls = the featured hero | 100 pulls → guaranteed Legendary+ | Rotates every 2 weeks |
| **Element Banner** | Restricted to one element | Same as standard | Monthly rotation |
| **Friend Summon** | Common/Uncommon only | None | Cheap (FP) |

### Rates (standard banner)

| Tier | Rate |
|---|---|
| Common | 50% |
| Uncommon | 25% |
| Rare | 15% |
| Epic | 7% |
| Legendary | 2.5% |
| Mythic | 0.5% |

### Pity

- **Legendary+ pity** at 100 pulls (counter resets on any Legendary+ pull).
- **Mythic pity** at 300 pulls (separate counter, no reset).
- Pity carries across **Standard ↔ Featured** (NOT Element, NOT Friend).
- Pity persists across sessions (server-side from Phase 9).

### Multi-pull (10x)

Cost: 9x the single-pull price (10% discount).
Guarantee: at least one Rare+ in any 10-pull.
UX: cinematic with skip option (always skippable).

## Weapon gacha (separate banner)

Weapons are a parallel collection system. **Separate banner, separate pity,
separate gems pool** (weapon gems vs hero gems — gain both from quests, spend
on each banner separately, prevents "I burn it all on heroes and have no
weapons" feel-bad).

Or simpler: single gem currency, two banners share it. Player choice.
**Recommended:** shared gems, separate pity. Players want flexibility.

### Weapon rarity

Same hybrid system as heroes (Common → Mythic, 1★–5★ within tier).

### Weapon banners

| Banner | Pool | Pity |
|---|---|---|
| **Standard Weapons** | All non-event weapons | 80 pulls → guaranteed Legendary+ |
| **Featured Weapon** | Boosts the banner's signature weapon | 80 pulls + signature 50/50 |

### Weapon stats

Each weapon has:

- **Base ATK** (or HP for off-hand weapons)
- **Sub-stat** (CRIT_RATE / CRIT_DMG / SPD / ACC etc., random within range)
- **Passive** — flavored effect (e.g. "First skill each battle deals +30%")
- **Refinement level** (R1–R5)

### Refinement (Star Rail's "Light Cone" model)

Stack 5 copies of the same weapon → R5 max.

| Refinement | Passive scale |
|---|---|
| R1 | 100% (base) |
| R2 | 125% |
| R3 | 150% |
| R4 | 175% |
| R5 | 200% |

R1 is fully usable; R5 is endgame chase. **Critical:** never gate viability
behind R5. The base R1 must already feel good.

### Weapon classes

Restrict weapons by hero class — keeps weapon identity strong.

| Hero class | Weapon types |
|---|---|
| Attacker | Sword, Axe, Spear |
| Defender | Shield, Hammer |
| Healer | Staff, Wand |
| Buffer | Tome, Lyre |
| Debuffer | Dagger, Whip |
| Ranger | Bow, Crossbow |

A weapon can only equip on its class. Reduces inventory bloat and lets us
balance per-class.

## Gear (Phase 7) — separate from weapons

| Slot | Stat focus |
|---|---|
| **Armor** | MAX_HP |
| **Helmet** | MAX_HP / RES |
| **Boots** | SPD |
| **Accessory** | CRIT_RATE / CRIT_DMG |
| **Relic** | LUK / unique effects |
| **Charm** | Free roll (random) |

Note: there's **no weapon slot in gear** — weapons are their own system. Six
gear slots + one weapon = 7 equipment items per hero.

**Rarity tiers** (color-coded): same hybrid as heroes / weapons (Common → Mythic).

**Stat rolls:**
- 1 main stat (slot-locked).
- 1–5 sub-stats (count based on rarity).
- Each stat is a roll within a range.

**Sets:**
- 2-piece bonus (small)
- 4-piece bonus (significant)

**Reforging:**
- Spend gold to reroll one sub-stat.
- Cost scales with rarity.

## Loops (player time-scale)

| Loop | Duration | Reward | Example |
|---|---|---|---|
| **Micro** | 30 seconds | Damage popup, crit, lucky proc | A single combat turn |
| **Short** | 2–5 minutes | Stage clear, XP, gold | Dungeon stage |
| **Session** | 20–30 minutes | Stamina spent, dailies done | Login + clear + a summon |
| **Daily** | A day | Login bonus, daily quests, arena attempts | Login streak |
| **Weekly** | 7 days | Weekly raid, weekly quests, arena reset | Boss raid clear |
| **Long-term** | Weeks/months | Ascending a hero, promoting a tier | Building a favorite |
| **Meta** | Months+ | Mythic Awakening, tower rank #1, guild rank | Player identity |

## Daily / weekly quests

**Daily** (7 quests, ~15 min total):
- Win 3 battles
- Use a skill 10 times
- Spend 60 stamina
- Summon 1 hero or weapon (any banner)
- Reach a daily dungeon clear
- Complete a tower floor
- Log in (free)

**Weekly** (5 quests):
- Win 20 battles
- Ascend any hero
- Clear element trial
- Clear boss raid tier
- Spend 1000 gems

## Anti-frustration design

- **Always-pity:** every pull moves you closer to a guaranteed Legendary+.
- **Soul stones / weapon shards:** any duplicate is progress.
- **Stamina cap forgiving:** overflow is the only loss for missed days.
- **No premium-only heroes or weapons:** everything is craftable via stones.
- **R1 weapons are fully viable:** R5 is optional chase.
- **Skip animations:** every animation > 2s has a skip button. Always.
