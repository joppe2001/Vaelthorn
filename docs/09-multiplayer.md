# 09 — Multiplayer

Everything that involves other players. Built on Nakama — see [10 — Server](10-server.md)
for the backend specifics.

## Ground rule: server-authoritative

The moment two players' actions affect each other, **the server owns combat
resolution**. Client → server: "I want to use Skill X on Target Y." Server
runs the same damage formula, validates, broadcasts the result. Client just
renders.

This eliminates cheating (save-file editing, packet hacks, time manipulation)
and is the only sustainable architecture for live multiplayer.

## What ships and when

| System | Phase | Type | Why this order |
|---|---|---|---|
| **Async Arena** | 10 | Async PvP | Easiest multiplayer, gives leaderboards immediately |
| **Guilds** | 11 | Social only | Build the fabric before content depends on it |
| **Guild Boss Raids** | 12 | Async cooperative | First boss content. Async = forgiving to build. |
| **Co-op Boss Raids** | 13 | Real-time cooperative | Hardest tech; only after the rest is solid |

**Explicitly NOT in v1–v4:** real-time GvG / world boss / ranked seasonal
PvP beyond async arena. Those are v5+ if ever.

---

## 1. Async PvP Arena (Phase 10)

The first multiplayer feature. No real-time required.

### Player setup

Each player designates a **Defense Team** of 5 heroes. This team auto-fights
when other players challenge them. The Defense Team can be changed any time
but the rank only updates on the next attack against you.

### Attack flow

1. Player taps **Arena**.
2. Server returns 3 opponents at similar rank.
3. Player picks one, picks their attack team.
4. Server simulates the battle using:
   - Attacker's chosen team (current stats).
   - Defender's saved Defense Team snapshot (stats as-of last refresh).
   - A deterministic seed.
5. Server returns the battle log (turn by turn).
6. Client plays the battle out animation-by-animation.
7. Player can **skip to result** at any time.

### Defense AI

The defender's heroes are auto-played by a scripted AI:

- Ultimate is used when gauge is full.
- Skills are used in priority order based on class (Healer heals lowest HP,
  Attacker targets lowest HP enemy, etc.).
- Same AI used for story dungeon enemies (shared code).

Players can set a **Skill Priority** for their defenders (advanced setting):
"Use Skill 2 before Skill 1," "Save Ultimate for enemy below 30%," etc. Late-
game depth without forcing it on new players.

### Rank ladder

| Rank | Range | Reward tier |
|---|---|---|
| Bronze | 0–999 | Daily gems trickle |
| Silver | 1000–1999 | + soul stones |
| Gold | 2000–2999 | + promotion stones |
| Platinum | 3000–3999 | + epic gear |
| Diamond | 4000–4999 | + legendary materials |
| Master | 5000+ | + Mythic shop access |
| Grandmaster | Top 100 globally | Season frame + exclusive title |

- Win: +20–35 rank points (more vs higher-ranked opponents).
- Loss: -10–25 rank points.
- Rank floor per tier (e.g. Platinum 3000 minimum — you don't drop back).

### Seasons

4-week seasons. End-of-season:
- Rewards distributed by final rank (gems, gear, soul stones, exclusive frame).
- Rank decays: everyone above Platinum drops by 1 tier.
- Master and Grandmaster reset to Master entry (3500).

### Arena Honor currency

Earn 10–25 Honor per win. Spend in **Arena Shop** on:
- Soul stones (rotating, per-hero)
- Promotion stones
- Cosmetic frames / borders

### Telemetry to watch

- Win rate around 45–55% for matched ranks → matchmaking is fair.
- Defense team diversity (if 80% of top players run the same team → meta is too narrow → buff alternatives).
- Drop-off after first arena loss (the most common churn point).

---

## 2. Guilds (Phase 11)

Persistent groups. Pre-requisite to all cooperative content.

### Creating / joining

- Create cost: 100,000 gold + player level 20.
- Custom name (filtered for slurs), icon (from set), region tag, description.
- **Min level to apply:** guild leader sets.
- **Auto-accept** toggle.

### Roles

| Role | Permissions |
|---|---|
| **Leader** | Everything; disband, transfer leadership |
| **Officer** (3 slots) | Accept/kick members, change guild settings, manage raid scheduling |
| **Member** | Chat, participate in raids, contribute |

### Guild progression

| Tier | Cost | Perks |
|---|---|---|
| Bronze | Start | Chat, 15 members |
| Silver | 1M guild XP | +5 members, +5% gold from dungeons |
| Gold | 3M | +5 members, daily 50 gems |
| Platinum | 10M | +5 members, harder boss tier unlocks |
| Diamond | 30M | 30 members, all perks max |

Guild XP earned from member dungeon clears, raid contributions, daily quests.

### Guild Chat

- Server-persistent, last 200 messages.
- Profanity filter on by default (toggleable per user).
- @mentions, links, hero/weapon links (drop a hero card into chat).
- Mod commands for officers (mute, clear).

### Guild Quests

Collective dailies — all members contribute toward shared goals:

- Total: 200 dungeon clears today
- Total: 50 arena wins
- Total: 10 boss raid attempts

Completion rewards: Guild Coins, gems, raid energy refills.

### Guild Coins

Earn from guild quests + raid participation. Spend in **Guild Shop**:
- Soul stones (rotating)
- Phoenix Feathers (slow trickle — primary source is raids)
- Cosmetic guild flags and emotes

---

## 3. Guild Boss Raids (Phase 12)

Async cooperative content. Members chip away at a shared boss over the week.

### Boss spawn

- Spawns Monday 00:00 UTC, expires Sunday 23:59.
- Boss tier scales with guild tier (Bronze gets boss tier 1, Diamond gets boss tier 5).
- 4 unique bosses rotating across weeks (Fire / Water / Earth / Wind).
- Boss element creates a meta puzzle (Fire boss week = water heroes shine).

### Attempts

- Each member: **3 attempts per day**.
- Each attempt = a single battle vs the boss (full party of 5).
- Battle time-capped at 5 minutes — if the boss isn't dead, total damage dealt counts.
- Boss does NOT carry HP between attempts within an attempt; it does across the whole week (every member's damage accumulates).

### Damage contribution

```text
guild_damage_total = sum(all member attempts' damage)

raid_progress     = guild_damage_total / boss_max_hp
clear_when        = raid_progress >= 1.0
```

If the guild clears, **all members** get the clear reward. The end-of-week
ranking by personal contribution determines bonus loot tier.

### Rewards

| Tier | Drops |
|---|---|
| Participation (any contribution) | 200 gems, 1 Phoenix Feather |
| Bronze contributor (bottom 50%) | + 1 raid gear piece |
| Silver contributor (middle 30%) | + 2 raid gear, 3 Phoenix Feathers |
| Gold contributor (top 20%) | + 3 raid gear, 5 Phoenix Feathers, 1 Mythic Dust |
| Guild clear bonus (all members if cleared) | + 1 random Legendary weapon shard |

**Phoenix Feathers** gate Legendary→Mythic promotion — guild raids are the
primary source. This is intentional: it ties endgame hero progression to
social participation without forcing PvP.

### Anti-leeching

- Low-effort attempts (< 5% boss damage) don't count for contribution tier.
- Officers can mark members as "active" / "inactive" — inactive don't share clear bonus.
- Auto-kick after 14 days no contribution (configurable).

---

## 4. Co-op Boss Raids (Phase 13)

Real-time multiplayer. The hardest tech. Saved for last.

### Format

- **3 players**, each bringing **5 heroes** = 15 total heroes vs 1 boss.
- Boss HP: massive (50M+).
- 10-minute time limit.

### Turn order

ATB across all 15 heroes (interleaved by SPD):

```text
on tick:
    for hero in all_15_heroes:
        hero.atb += hero.SPD * delta
        if hero.atb >= 100:
            queue_turn(hero)
            hero.atb = 0
```

Each hero acts when their ATB fills. Players take turns based on whose hero is up.

### Why turn-based forgives latency

Real-time PvP fighting games need < 50ms latency. Our turn-based system can
tolerate **500ms+** because:

- Animations have built-in delay.
- Turn input has no time pressure (10s per turn).
- Server resolves the whole turn before broadcasting.

This makes co-op raids deployable to global players from one VPS.

### Lobby flow

1. Player taps **Co-op Raid**.
2. **Find Match** (auto-fill from queue) OR **Create Room** (4-digit code to share).
3. Lobby: 3 slots, players join, each picks 5 heroes.
4. **Ready up.** When all 3 ready, raid begins.
5. After raid: results screen, "Play again" option keeps the same trio.

### Network resilience

- If a player disconnects: their heroes go idle (ATB still fills, but skill auto-resolves as basic attack on the boss).
- They can reconnect within 60 seconds and resume control.
- The server is always the source of truth — no host migration needed.

### Rewards

| Result | Drops |
|---|---|
| Defeat | 100 gems each, no gear |
| Victory (tier 1) | 1 Celestial Essence, 2 raid gear, 500 gems each |
| Victory (tier 3) | 2 Celestial Essence, 3 raid gear, 1000 gems each |
| Victory (tier 5, endgame) | 3 Celestial Essence, endgame Mythic gear, 2000 gems each |

**Celestial Essence** gates Mythic Awakening — this is the endgame ladder's
top rung.

### Difficulty tiers

5 difficulty tiers. Higher tiers unlock as guild progresses. Tier 5 is meant
to require a **coordinated Mythic-Awakened roster** to clear.

---

## Cross-cutting design rules

### Cheating defense (covered fully in [10 — Server](10-server.md))

- All combat resolved on server. Client only renders.
- All gacha rolled on server. Pity stored server-side.
- All currency transactions validated server-side.
- Rate limits on every RPC.

### Connection failure UX

- Offline grace: 60 seconds reconnect window for any battle.
- Mid-battle disconnect: server caches state, resumes on reconnect.
- Hard fail: battle marked "interrupted" → no penalty, no reward.

### Privacy / safety

- All chat persisted server-side for moderation.
- Report user flow → ban tooling for the operator.
- Profanity filter on by default.
- No DMs in v3 (avoid harassment surface). Guild chat is the only social channel.

### Localization-ready

- All player-facing text in i18n resource files from day 1.
- Don't worry about translations until v3+ — but architect for it now.

## What's NOT shipping in v4 (and why)

- **Real-time GvG (Guild vs Guild battles).** Latency-sensitive, schedule-driven,
  matchmaking complexity, balance nightmare. v5+ at earliest.
- **World Boss** (server-wide raid all players contribute to). Cool concept,
  requires massive ops attention. v5+.
- **Player-to-player trading.** Account security / RMT (real-money trading)
  liability. Never.
- **In-app purchases for currency.** Not a F2P game. Earn via play.

These can all be added later. Shipping without them is the right call.
