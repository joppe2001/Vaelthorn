# 08 — Roadmap

The phased build plan. Each phase ends with a playable, shippable result.

> Time estimates assume **solo, part-time** work (~10 hrs/week).
> Full-time you can compress by 2–3×. With a team of 3–4, ~2×.

## Release milestones at a glance

| Release | Phases | Months (part-time) |
|---|---|---|
| **v1.0 — Single-player launch** | 0–8 | 7–9 |
| **v2.0 — Online** | 9–10 | +5–6 |
| **v3.0 — Social** | 11–12 | +5–7 |
| **v4.0 — Co-op + live ops** | 13–14 | +5–7 |

---

## Phase 0 — Foundation (1 week)

Just get set up. Don't over-engineer.

- [ ] Install Godot 4.3+ (LTS).
- [ ] Install Aseprite.
- [ ] Create the project skeleton ([07 — Tech](07-tech.md) project structure).
- [ ] Initialize git, push to private GitHub.
- [ ] Pick a master palette (recommended: Endesga 64).
- [ ] Download 1–2 asset packs (1 character pack + 1 UI pack to start).
- [ ] Title scene loads a Hub scene. That's it.
- [ ] Configure pixel-perfect rendering (nearest-neighbor, integer scale).

**Exit:** project runs; Title → Hub works.

## Phase 1 — Battle MVP (2–3 weeks)

One hero vs one enemy. The combat core, end to end.

- [ ] HeroData / EnemyData Resource classes.
- [ ] 1 hero + 1 enemy `.tres` file.
- [ ] Pure-function `Damage.compute()`.
- [ ] 6×6 element table.
- [ ] Basic round-based turn order (sort by SPD).
- [ ] Battle scene: 2 sprites, 2 HP bars, attack button.
- [ ] Damage popups (float + fade).
- [ ] Win / lose detection → results screen.
- [ ] Tests: damage formula, element table, hit/dodge.

**Exit:** play a 1v1 battle, see crits and elemental advantage, win or lose.

## Phase 2 — Party Combat (3–4 weeks)

First version that feels like a real BF/IH-style fight.

- [ ] Expand battle to 5v5.
- [ ] Upgrade turn order to ATB (speed-tick).
- [ ] Skills: 3 active + 1 basic + 1 ultimate per hero.
- [ ] Cooldown UI.
- [ ] Ultimate gauge (charges from damage in/out).
- [ ] Ultimate cut-in animation (reusable template).
- [ ] Status effects: Burn, Stun, ATK_UP, DEF_DOWN.
- [ ] Status icons over units.
- [ ] Turn order indicator UI.
- [ ] Enemy AI: simple priority logic.
- [ ] Juice: screen shake, hit flash, element tint, SFX.
- [ ] Tests: status lifecycle, ultimate gauge fill rate.

**Exit:** 5v5 with skills, ultimates, status effects, and real visual juice.
This phase alone is a complete tactical battle game — could ship as a small
standalone on itch.io.

## Phase 3 — Hero Roster + Save (2–3 weeks)

The collection layer (local, no server yet).

- [ ] 10 starter heroes as `.tres` files ([03 — Heroes](03-heroes.md)).
- [ ] Hero Roster screen.
- [ ] Hero Detail screen (stats, skills, lore).
- [ ] Party Builder screen + auto-fill.
- [ ] Hero leveling (XP gain → level up).
- [ ] Save / Load JSON to `user://save.json`.
- [ ] Save versioning + migration scaffold.

**Exit:** collect heroes, build parties, save progress.

## Phase 4 — Dungeon Flow (2–3 weeks)

Content delivery.

- [ ] StageData / DungeonData Resources.
- [ ] Chapter 1: 8 stages.
- [ ] Dungeon Map + Stage Select screens.
- [ ] Stamina system.
- [ ] Battle Results with rewards.
- [ ] Drop tables.
- [ ] 3-star rating per stage.
- [ ] Stage replay.

**Exit:** real campaign loop. Start of game → finish Chapter 1.

## Phase 5 — Progression Depth (3–4 weeks)

The "why am I still playing" layer. Hybrid rarity ladder lives here.

- [ ] Ascension within tier (1★ → 5★ per tier).
- [ ] Promotion across tiers (Common → Uncommon → … → Mythic).
- [ ] Soul stones (per-hero dupe currency).
- [ ] Tier-specific Dust currencies.
- [ ] Promotion Stones (drop from promotion dungeons).
- [ ] Daily dungeons (gold / XP / dust rotation).
- [ ] Element Trial dungeons.
- [ ] Hero XP potions / instant-level items.
- [ ] Achievement system (~20 milestones).

**Exit:** the game has reasons to play *next week*.

## Phase 6 — Hero Gacha (2 weeks)

The dopamine engine for heroes.

- [ ] Summon screen with banner select.
- [ ] Pull animation (skippable, rarity foreshadowing).
- [ ] 10x pull with cinematic.
- [ ] Pity counters (Legendary+ at 100, Mythic at 300).
- [ ] Featured banner mechanic (50/50 on Legendary+).
- [ ] Friend summon (FP-only, low rarity).
- [ ] Soul stone shop for crafting any hero.

**Exit:** pulling heroes feels good and never feels hopeless.

## Phase 7 — Weapons (3–4 weeks)

Parallel collection system.

- [ ] WeaponData Resource.
- [ ] 20 starter weapons across classes.
- [ ] Weapon Inventory screen.
- [ ] Weapon equip / unequip flow.
- [ ] Weapon refinement (R1 → R5 via dupes).
- [ ] Weapon shards (per-weapon dupe currency).
- [ ] Weapon gacha banner (separate from hero gacha).
- [ ] Standard + Featured weapon banners with pity (80 pulls).

**Exit:** every hero has a weapon, the build-craft layer is real.

## Phase 8 — Single-player Polish + Release (2–3 weeks)

Make v1.0 actually shippable.

- [ ] Gear system (6 slots, rarity rolls, set bonuses) ([04](04-progression.md)).
- [ ] Hero merging / Awakening preview (full Awakening unlocks in Phase 12+).
- [ ] SFX pass (every action has a sound).
- [ ] Music pass (3–5 tracks).
- [ ] UI transitions pass.
- [ ] Settings screen complete.
- [ ] Credits with asset attribution.
- [ ] Tutorial / FTU flow.
- [ ] Bug bash + playtest with 3–5 friends.
- [ ] Export presets: Windows / macOS / Linux.
- [ ] itch.io page (screenshots, GIFs, description, demo).

**Exit: v1.0 ships on itch.io.** This is the milestone that proves the project
is real.

---

## v2.0 — Online layer

## Phase 9 — Cloud save + accounts (3–4 weeks)

Move the source of truth to the server. No multiplayer features yet.

- [ ] Spin up Nakama on a $10/mo VPS (Docker Compose).
- [ ] Set up PostgreSQL backups (pg_dump daily to Cloudflare R2).
- [ ] Account system: email + Google + Apple login.
- [ ] Migrate save schema to server tables.
- [ ] Sync local save → server on first login.
- [ ] Local save becomes a *cache* of server state.
- [ ] Server-side gacha (pity stored server-side, RNG server-side).
- [ ] Server-side combat validation (anti-cheat baseline).
- [ ] Network error handling (offline grace, reconnect, retry).

**Exit:** save lives on the server. Cheating becomes hard. Players can play
on multiple devices. No multiplayer yet.

## Phase 10 — Async PvP Arena (4–6 weeks)

The first multiplayer feature. Async = no real-time pressure.

- [ ] Defense team setup (player picks 5 heroes to defend).
- [ ] Arena lobby UI.
- [ ] Server matchmaking by rank.
- [ ] Server-resolved battles (deterministic replay from seed + actions).
- [ ] Replay viewer (watch attacks on your defense).
- [ ] Rank ladder (Bronze → Silver → … → Master → Grandmaster).
- [ ] Season system (4-week seasons with reset + rewards).
- [ ] Arena Honor currency + Arena Shop.
- [ ] Leaderboards.

**Exit: v2.0 ships.** Online launch announced.

---

## v3.0 — Social layer

## Phase 11 — Guilds (3–4 weeks)

Persistent groups. No competitive features yet.

- [ ] Guild creation flow (cost: gold, level requirement).
- [ ] Guild member list (max 30).
- [ ] Guild chat (server-side, persistent messages).
- [ ] Guild XP and tier (Bronze → Silver → Gold → Platinum → Diamond).
- [ ] Guild quests (collective dailies).
- [ ] Guild Coins currency + Guild Shop.
- [ ] Roles: Leader, Officer, Member.
- [ ] Apply / accept / kick flow.

**Exit:** guilds exist as a social fabric. No gameplay impact yet beyond perks.

## Phase 12 — Guild Boss Raids (4–6 weeks)

Async cooperative content. Guild members chip away at a shared boss.

- [ ] Weekly boss spawn (scales with guild tier).
- [ ] Each member: 3 attempts/day.
- [ ] Per-attempt damage accumulates to guild total.
- [ ] Damage leaderboard within guild.
- [ ] Loot distribution by damage contribution + participation.
- [ ] Phoenix Feathers drop (gate Legendary→Mythic promotion behind raids).
- [ ] Boss rotation (4 unique bosses, one per week).

**Exit: v3.0 ships.**

---

## v4.0 — Co-op + live ops

## Phase 13 — Co-op Boss Raids, real-time (6–8 weeks)

The hard one. Real-time multiplayer turn-based combat.

- [ ] Match lobby (party-finder + manual room codes).
- [ ] 3 players bring 5 heroes each → 15 heroes in battle.
- [ ] Turn order interleaved by SPD across all 3 parties.
- [ ] Server-authoritative turn resolution (every action validated).
- [ ] 10-minute time limit per raid.
- [ ] Network resilience: disconnect handling, host migration not needed (server is host).
- [ ] Celestial Essence drops (gate Mythic Awakening).
- [ ] Endgame raid gear.

**Exit:** real-time co-op is live. The hardest tech is shipped.

## Phase 14 — Live ops + content cadence (ongoing)

The treadmill that keeps the game alive.

- [ ] **Hero of the Month** — 1 new hero per month minimum.
- [ ] Story chapters 2–10 (one per quarter).
- [ ] Event dungeons (limited-time, themed, rotating).
- [ ] Seasonal events (Halloween, Anniversary, etc.).
- [ ] Weekly maintenance + patch cadence.
- [ ] Community Discord + feedback loop.
- [ ] Telemetry (player drop-off, retention, time-to-ascend) — make data-driven decisions.

**Exit:** there is no exit. This is live ops.

---

## Risk callouts

These derail solo projects most often. Watch for them.

| Risk | Mitigation |
|---|---|
| **Scope creep on heroes** | Hard-cap per phase. Phase 3 = exactly 10. Phase 8 = exactly 20. |
| **Sprite work bottleneck** | Use asset packs. Don't draw originals until v2 or later. |
| **Gacha balance** | Track rates in playtest. Soften pity, don't change base rates. |
| **UI takes 30% of dev time** | Budget for it. 9-slice panel library mandatory. |
| **Save format churn** | Version from day 1. Write migration the first time. |
| **Server complexity** | Defer until Phase 9. Don't even *think* about Nakama until v1.0 is out. |
| **Burnout** | Each phase ships. Break between phases. Show a friend every 2 weeks. |
| **Live ops scope on a solo dev** | Phase 14 is realistically 1 hero / 1 event per 2 months solo. Be honest about cadence. |

## Stop conditions

If any of these is true, stop and reconsider:

- You can't articulate what makes a battle *fun* to play.
- 3 heroes in a row don't have a clear identity.
- A phase has run 3× its time estimate and you're not near exit.
- You haven't shown the build to anyone in 6 weeks.
- You started Phase 9 before v1.0 launched on itch.io.

Stopping is not failing. *Stopping and pivoting* is the indie game development loop.

## What's next

After this design doc feels right:

1. **Phase 0 next session:** I scaffold the Godot project, set up palette,
   write Title + Hub scenes, configure git. You open Godot to a working
   prototype on Day 1.
2. **Phase 1 in the session after:** Battle MVP, end to end.

When you've installed Godot, tell me and we'll start Phase 0.
