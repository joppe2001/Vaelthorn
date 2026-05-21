# 03 — Heroes

Heroes are the content engine. Every other system exists to make collecting
and using them feel good.

## Hybrid rarity system

Two axes: a **named tier** (how rare to acquire) and a **star count** (ascension
progress within tier). Maximum granularity.

### Named tiers

| Tier | Color | Acquisition rate (standard banner) |
|---|---|---|
| **Common** | Gray | 50% |
| **Uncommon** | Green | 25% |
| **Rare** | Blue | 15% |
| **Epic** | Purple | 7% |
| **Legendary** | Gold | 2.5% |
| **Mythic** | Crimson | 0.5% |
| **Celestial** | Rainbow | Endgame-only, not summonable (Phase 14+) |

### Stars within tier

Every hero has 1★–5★ within their current tier. Stars are gained through
**ascension** (consuming same-hero dupes + materials).

### Promotion (tier-up)

When a hero hits **5★ at their current tier**, they can be promoted to the
next tier — but starting back at 1★. This is the core long-game loop.

```text
Acquire:  Rare 1★
Ascend:   Rare 1★ → Rare 5★  (5 same-hero dupes total + dust)
Promote:  Rare 5★ → Epic 1★  (1 same-tier dupe of another hero + materials + gold)
Ascend:   Epic 1★ → Epic 5★
Promote:  Epic 5★ → Legendary 1★
... and so on, up to the hero's ceiling
```

### Ceiling per base tier

A hero's **base tier** is the tier they're summoned at. It caps how high they
can promote.

| Base tier at summon | Maximum reachable |
|---|---|
| Common | Epic 5★ |
| Uncommon | Legendary 3★ |
| Rare | Legendary 5★ |
| Epic | Mythic 3★ |
| Legendary | Mythic 5★ |
| Mythic | Mythic 5★ + **Awakened** |

Higher base tier = higher ceiling. This gives gacha pulls real meaning while
still letting low-tier heroes have a long progression path.

### Awakening (Mythic only, endgame)

A Mythic 5★ hero can be **Awakened** by consuming:
- 3 dupes of that exact hero
- 1 Celestial Essence (rare drop from co-op raid endgame)
- 5,000,000 gold

Awakening:
- Adds a new passive ("Awakened Passive" — designed per-hero)
- Unlocks the **Ultimate+ form** (enhanced ultimate with extra hit / effect)
- Updates portrait with a glow border
- Maxes level cap at 150

### Stat scaling across the ladder

Each tier promotion bumps base stats by **+25%**. Each star adds **+5%** within
tier. Result: a fully-built Mythic 5★ Awakened hero is roughly **6×** the
power of a Common 1★ baseline, before gear or weapons.

```text
power_multiplier(tier, stars) = 1.25^tier_index * (1 + 0.05 * (stars - 1))

# tier_index: Common=0, Uncommon=1, Rare=2, Epic=3, Legendary=4, Mythic=5
```

## Classes

Six. Each has a distinct role in a party of 5. A well-built team has 2–3
classes represented.

| Class | Role | Sample skills |
|---|---|---|
| **Attacker** | Single-target burst | High-power AoE, executions |
| **Defender** | Tank / aggro magnet | Provoke, damage reduction, counter |
| **Healer** | Restore HP | Single + AoE heal, cleanse, revive |
| **Buffer** | Boost allies | ATK_UP, CRIT_UP, SPD_UP, shields |
| **Debuffer** | Cripple enemies | DEF_DOWN, status effects, dispel buffs |
| **Ranger** | Sustained DPS + utility | Multi-hit, break, debuffs on hit |

Players should be encouraged to **bring at least one Healer or Defender** for
any non-trivial dungeon. Enemy AI in late stages should punish all-Attacker teams.

## Hero data resource

```text
HeroData {
    id:              string
    display_name:    string
    lore:            string

    element:         Element
    class_type:      Class
    base_tier:       int                 # 0..5 (Common..Mythic)

    # base stats at Lv 1, tier 0 (Common), 1★
    base_hp:         int
    base_atk:        int
    base_def:        int
    base_spd:        int
    base_crit_rate:  float
    base_crit_dmg:   float
    base_acc:        float
    base_eva:        float
    base_luk:        int
    base_res:        float

    skills:          Array<SkillData>      # 3 active skills
    ultimate:        SkillData             # base ultimate
    ultimate_plus:   SkillData             # awakened ultimate variant
    passive:         PassiveData
    awakened_passive: PassiveData          # unlocked at Awakening

    sprite_set:      SpriteFrames
    portrait:        Texture2D
    portrait_awakened: Texture2D
}
```

## Leveling

Per hero. XP from battles (win bonus + per-kill).

```text
xp_required_for_level(L) = floor(50 * L^1.7)
```

Level caps by tier:

| Tier | Level cap |
|---|---|
| Common | 40 |
| Uncommon | 60 |
| Rare | 80 |
| Epic | 100 |
| Legendary | 120 |
| Mythic | 140 |
| Mythic Awakened | 150 |

Stats scale with level:

```text
stat(L) = base_stat * tier_multiplier * star_multiplier * (1 + 0.04 * (L - 1) + 0.001 * (L - 1)^2)
```

## Ascension costs (within tier)

5 ascension steps per tier (1★ → 5★). Each step requires:

| Step | Dupes (same hero) | Dust | Gold |
|---|---|---|---|
| 1★→2★ | 1 | 5 | 5,000 |
| 2★→3★ | 1 | 10 | 15,000 |
| 3★→4★ | 2 | 25 | 50,000 |
| 4★→5★ | 3 | 50 | 200,000 |

Dust is **tier-specific** (Common Dust, Rare Dust, Epic Dust, etc.).

## Promotion costs (tier → next tier)

| From → To | Same-hero dupe | Same-tier sacrifice | Premium material | Gold |
|---|---|---|---|---|
| Common → Uncommon | 1 | 2 Common heroes | 5 Promotion Stones | 50,000 |
| Uncommon → Rare | 1 | 2 Uncommon heroes | 10 Promotion Stones | 200,000 |
| Rare → Epic | 1 | 3 Rare heroes | 25 Promotion Stones | 800,000 |
| Epic → Legendary | 2 | 3 Epic heroes | 50 Promotion Stones + 1 Phoenix Feather | 3,000,000 |
| Legendary → Mythic | 3 | 4 Legendary heroes | 100 Promotion Stones + 3 Phoenix Feathers | 10,000,000 |

Phoenix Feathers drop from co-op raid endgame and guild bosses. Locks the
endgame loop behind the social layer.

## Soul stone path (no-luck progression)

Every duplicate hero converts to **soul stones** of that hero. Soul stones
craft new copies of that hero outright — no luck required.

| Dupe | Soul stones earned |
|---|---|
| Common dupe | 5 |
| Uncommon dupe | 15 |
| Rare dupe | 40 |
| Epic dupe | 100 |
| Legendary dupe | 300 |
| Mythic dupe | 1,000 |

To craft a hero (any tier) at 1★:

| Tier | Stones needed |
|---|---|
| Common | 50 |
| Uncommon | 120 |
| Rare | 300 |
| Epic | 800 |
| Legendary | 2,500 |
| Mythic | 8,000 |

This guarantees that grinding any specific hero eventually unlocks them, even
with terrible RNG.

## Passives

Always-on effects. Define hero identity. Pick *one* per hero — don't dilute.

Examples:

- **Ember Spark** (Fire-Attacker): On crit, apply Burn (2 turns).
- **Mountainheart** (Earth-Defender): Below 50% HP, +30% DEF + force-aggro all enemies.
- **Flow** (Water-Healer): At start of turn, all allies regen 2% MAX_HP.
- **Stormcaller** (Wind-Buffer): All allied basic attacks gain +10% crit rate.
- **Shroud** (Dark-Debuffer): All debuffs you apply last +1 turn.
- **Sentry** (Light-Ranger): First skill each battle is guaranteed crit.

## Awakened passives (Mythic only)

When awakened, a hero gains a *second* passive that's flavor-tied to the first.
Example: Ember Spark → **Ember Storm** (on crit, burn ALL enemies for 1 turn).

## Skill identity

Each hero's kit should map to a clear theme. Read the kit, know the hero.

Anti-pattern: two damage skills + one generic buff. No identity.
Good pattern: a hero whose kit revolves around burning, or shielding, or
stunning, or chain-attacking.

## Starter roster (Phase 3 target)

Ship Phase 3 with **10 heroes**. Coverage rules: all 6 elements, all 6 classes,
mix of base tiers.

| # | Element | Class | Working name | Base tier |
|---|---|---|---|---|
| 1 | Fire | Attacker | Ember Knight | Rare |
| 2 | Water | Defender | Tideguard | Rare |
| 3 | Earth | Healer | Grove Priestess | Rare |
| 4 | Wind | Ranger | Stormarcher | Rare |
| 5 | Light | Buffer | Dawn Herald | Epic |
| 6 | Dark | Debuffer | Veilstalker | Epic |
| 7 | Fire | Ranger | Cinderhound | Uncommon |
| 8 | Water | Healer | Tidesinger | Epic |
| 9 | Earth | Defender | Stoneward | Uncommon |
| 10 | Wind | Attacker | Galelancer | Legendary |

## Hero authoring workflow

A new hero should take **under 30 minutes** to add (sprite work aside):

1. Duplicate an existing `.tres` file.
2. Edit name, element, class, base tier, stats.
3. Wire up a sprite set (drop folder of PNG strips).
4. Define 3 skills (often by reusing skills from the shared library).
5. Test in a debug battle scene.

If the workflow takes longer than this, build tools — heroes are the content
gate for every phase past 3.
