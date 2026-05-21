# 10 — Server

The backend stack for Phases 9+. Cheating defense, multiplayer, persistent
state. Built on Nakama.

> Do not touch anything in this doc until v1.0 ships on itch.io.
> Phase 9 starts after Phase 8 lands. Discipline is the project's life support.

## Why Nakama

Open-source game server. Self-hosted, no per-MAU fees, no vendor lock-in.

Built-in primitives:

- **Authentication** (email, Google, Apple, Steam, custom)
- **User accounts + storage objects** (per-user persistent JSON)
- **Matchmaking + parties** (for arena, co-op)
- **Realtime matches** (server-authoritative game state)
- **Leaderboards + tournaments** (arena ladder, seasons)
- **Guilds (called "groups")** + chat
- **Notifications** (raid started, guild kicked, etc.)
- **Server-side TypeScript / Lua / Go** runtime for custom RPCs

Used by real shipped games. Reasonable docs. The Godot SDK is community-
maintained but functional ([nakama-godot](https://github.com/heroiclabs/nakama-godot)).

## Architecture

```text
+--------------------+       wss + https        +---------------------+
|   Godot Client     | <-----------------------> |    Nakama Server    |
|   (player device)  |                           |    (TypeScript)     |
+--------------------+                           +---------------------+
                                                          |
                                                          | local socket
                                                          v
                                                 +---------------------+
                                                 |     PostgreSQL      |
                                                 |   (server state)    |
                                                 +---------------------+

                                                 +---------------------+
                                                 |   pg_dump → R2      |
                                                 |     (daily)         |
                                                 +---------------------+
```

- One VPS runs Docker Compose with Nakama + Postgres.
- Players connect via WebSocket (combat) + HTTPS (RPCs).
- Daily backups to Cloudflare R2 (or S3, or any object store).
- A second VPS for staging / dev. Total: $20–40/mo until ~10k MAU.

## Server-authoritative combat

The single most important security principle. Here's the flow.

### Client → Server: "I used skill"

```ts
// Client (Godot, sent over WebSocket)
{
  "type": "combat_action",
  "battle_id": "uuid",
  "actor_hero_instance_id": "hero-uuid",
  "skill_id": "flame_slash",
  "target_ids": ["enemy-uuid-1"]
}
```

### Server: validate + resolve + broadcast

```ts
// Server (TypeScript runtime)
function handleCombatAction(payload, state) {
  // 1. validate the actor is whose turn it is
  if (state.current_turn.actor !== payload.actor_hero_instance_id) {
    return error("not your turn");
  }

  // 2. validate the skill exists and is off cooldown
  const skill = state.hero.skills.find(s => s.id === payload.skill_id);
  if (!skill || skill.cooldown_remaining > 0) {
    return error("skill unavailable");
  }

  // 3. validate the target is alive and a valid target type
  const target = state.units.find(u => u.id === payload.target_ids[0]);
  if (!target || target.hp <= 0) {
    return error("invalid target");
  }

  // 4. run the SAME damage formula as the client
  const result = Damage.compute(
    state.hero.stats,
    target.stats,
    skill,
    state.rng
  );

  // 5. apply result to state
  target.hp -= result.damage;
  state.rng.advance();

  // 6. broadcast the result to all watchers
  broadcast(state.battle_id, {
    type: "combat_result",
    actor: payload.actor_hero_instance_id,
    target: target.id,
    damage: result.damage,
    is_crit: result.is_crit,
    is_lucky: result.is_lucky
  });
}
```

Client just renders the broadcast. **The client never decides damage.**

### Port the damage formula carefully

The client's `Damage.compute()` in GDScript must be **bit-exact** with the
server's TypeScript version. Same formula, same constants, same RNG sequence.

Strategy: write the formula once in pseudocode, then port to both languages
with a shared **test vector** file:

```json
[
  {
    "name": "basic_attack_no_crit",
    "attacker": { "atk": 500, "crit_rate": 0.0, "crit_dmg": 1.5, "luk": 0, "element": 0 },
    "target":   { "def": 100, "element": 1 },
    "skill":    { "power": 1.0 },
    "rng_seed": 12345,
    "expected": { "damage": 425, "is_crit": false, "is_lucky": false }
  },
  ...
]
```

Both client and server tests load this file and must produce identical output.
Any discrepancy is a bug; fix immediately.

## RPC surface

The full list of server-side RPCs the client can call.

| RPC | Purpose | Phase |
|---|---|---|
| `rpc_login` | Authenticate, return session | 9 |
| `rpc_pull_save` | Get latest player state | 9 |
| `rpc_summon_hero` | Pull on hero gacha banner | 9 |
| `rpc_summon_weapon` | Pull on weapon gacha banner | 9 |
| `rpc_ascend_hero` | Spend dupes + dust to ascend | 9 |
| `rpc_promote_hero` | Promote hero tier | 9 |
| `rpc_battle_resolve` | Resolve a dungeon battle (input: actions, output: result + drops) | 9 |
| `rpc_arena_find_opponents` | Get 3 matchmade opponents | 10 |
| `rpc_arena_battle` | Resolve an arena battle | 10 |
| `rpc_arena_set_defense` | Update defense team | 10 |
| `rpc_arena_leaderboard` | Top players | 10 |
| `rpc_guild_create` | Create a new guild | 11 |
| `rpc_guild_join` / `_leave` / `_kick` | Membership management | 11 |
| `rpc_guild_chat_send` | Send a chat message | 11 |
| `rpc_raid_start` | Start a guild raid attempt | 12 |
| `rpc_raid_contribute` | Submit damage contribution | 12 |
| `rpc_raid_claim` | Claim end-of-week rewards | 12 |
| `rpc_coop_create_room` | Create a co-op raid room | 13 |
| `rpc_coop_join_room` | Join via code or matchmaking | 13 |
| (realtime match) | All in-raid combat goes through Nakama's realtime match handler | 13 |

## Storage model (Postgres)

Nakama auto-creates auth + groups + leaderboards tables. We add custom tables
for game state.

```sql
-- one row per user, mirrors Nakama's user table
CREATE TABLE player_state (
  user_id            UUID PRIMARY KEY REFERENCES users(id),
  player_level       INT NOT NULL DEFAULT 1,
  player_xp          BIGINT NOT NULL DEFAULT 0,
  gold               BIGINT NOT NULL DEFAULT 0,
  gems               INT NOT NULL DEFAULT 100,
  stamina            INT NOT NULL DEFAULT 100,
  stamina_last_tick  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  pity_hero_legendary  INT NOT NULL DEFAULT 0,
  pity_hero_mythic     INT NOT NULL DEFAULT 0,
  pity_weapon_legendary INT NOT NULL DEFAULT 0,
  settings_json      JSONB NOT NULL DEFAULT '{}',
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE heroes_owned (
  instance_id        UUID PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES users(id),
  hero_template_id   TEXT NOT NULL,    -- e.g. "ember_knight"
  tier               INT NOT NULL,     -- 0..5 (Common..Mythic)
  stars              INT NOT NULL,     -- 1..5
  level              INT NOT NULL DEFAULT 1,
  xp                 BIGINT NOT NULL DEFAULT 0,
  awakened           BOOLEAN NOT NULL DEFAULT FALSE,
  equipped_weapon_id UUID NULL,
  gear_armor_id      UUID NULL,
  gear_helmet_id     UUID NULL,
  gear_boots_id      UUID NULL,
  gear_accessory_id  UUID NULL,
  gear_relic_id      UUID NULL,
  gear_charm_id      UUID NULL,
  acquired_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX heroes_owned_user ON heroes_owned(user_id);

CREATE TABLE weapons_owned (
  instance_id        UUID PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES users(id),
  weapon_template_id TEXT NOT NULL,
  tier               INT NOT NULL,
  stars              INT NOT NULL,
  refinement         INT NOT NULL DEFAULT 1,  -- 1..5
  sub_stats_json     JSONB NOT NULL,
  acquired_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX weapons_owned_user ON weapons_owned(user_id);

CREATE TABLE gear_inventory (
  instance_id        UUID PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES users(id),
  slot               TEXT NOT NULL,    -- armor, helmet, etc.
  tier               INT NOT NULL,
  set_id             TEXT NULL,
  main_stat_json     JSONB NOT NULL,
  sub_stats_json     JSONB NOT NULL
);
CREATE INDEX gear_inventory_user ON gear_inventory(user_id);

CREATE TABLE soul_stones (
  user_id            UUID NOT NULL REFERENCES users(id),
  hero_template_id   TEXT NOT NULL,
  count              INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, hero_template_id)
);

CREATE TABLE weapon_shards (
  user_id            UUID NOT NULL REFERENCES users(id),
  weapon_template_id TEXT NOT NULL,
  count              INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, weapon_template_id)
);

CREATE TABLE arena_defense_teams (
  user_id            UUID PRIMARY KEY REFERENCES users(id),
  hero_1_id          UUID NULL,
  hero_2_id          UUID NULL,
  hero_3_id          UUID NULL,
  hero_4_id          UUID NULL,
  hero_5_id          UUID NULL,
  rank_points        INT NOT NULL DEFAULT 1000,
  season_high        INT NOT NULL DEFAULT 1000,
  updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE arena_battles (
  battle_id          UUID PRIMARY KEY,
  attacker_id        UUID NOT NULL,
  defender_id        UUID NOT NULL,
  rng_seed           BIGINT NOT NULL,
  actions_json       JSONB NOT NULL,
  attacker_won       BOOLEAN NOT NULL,
  rank_delta_attacker INT NOT NULL,
  rank_delta_defender INT NOT NULL,
  fought_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX arena_battles_attacker ON arena_battles(attacker_id, fought_at DESC);

CREATE TABLE guilds (
  guild_id           UUID PRIMARY KEY,
  name               TEXT UNIQUE NOT NULL,
  description        TEXT,
  icon_id            TEXT NOT NULL,
  tier               INT NOT NULL DEFAULT 0,
  xp                 BIGINT NOT NULL DEFAULT 0,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE guild_members (
  guild_id           UUID NOT NULL REFERENCES guilds(guild_id),
  user_id            UUID NOT NULL REFERENCES users(id),
  role               TEXT NOT NULL,   -- leader, officer, member
  joined_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (guild_id, user_id)
);

CREATE TABLE raid_state (
  guild_id           UUID NOT NULL REFERENCES guilds(guild_id),
  week_start         DATE NOT NULL,
  boss_template_id   TEXT NOT NULL,
  total_damage       BIGINT NOT NULL DEFAULT 0,
  cleared            BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (guild_id, week_start)
);

CREATE TABLE raid_contributions (
  guild_id           UUID NOT NULL,
  week_start         DATE NOT NULL,
  user_id            UUID NOT NULL,
  attempts_used      INT NOT NULL DEFAULT 0,
  total_damage       BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (guild_id, week_start, user_id)
);
```

## Server-side gacha

All RNG happens server-side. The client never knows what they pulled until
the server tells them.

```ts
// server-side pseudocode
function rpcSummonHero(userId, bannerId): SummonResult {
  const state = loadPlayerState(userId);
  const banner = BANNERS[bannerId];

  // 1. validate gem cost
  if (state.gems < banner.cost) throw new Error("not enough gems");

  // 2. roll
  state.gems -= banner.cost;
  state.pity_hero_legendary += 1;
  state.pity_hero_mythic    += 1;

  const result = rollHero(banner, state.pity_hero_legendary, state.pity_hero_mythic);

  if (result.tier >= TIER_LEGENDARY) state.pity_hero_legendary = 0;
  if (result.tier === TIER_MYTHIC)   state.pity_hero_mythic    = 0;

  // 3. award the hero
  awardHero(userId, result.hero_template_id, result.tier, result.stars);

  // 4. log for audit
  logGachaPull(userId, bannerId, result, state.pity_hero_legendary, state.pity_hero_mythic);

  // 5. persist
  savePlayerState(userId, state);

  return result;
}
```

**Audit log every pull.** Disk is cheap; investigations are expensive.

## Anti-cheat baseline

| Vector | Defense |
|---|---|
| Save file editing | Server is source of truth — local save is a cache only |
| Packet replay | Each RPC has a server-issued nonce; replayed nonces rejected |
| Speed hacks | Server tracks stamina regen; client display doesn't matter |
| Impossible damage | Server resolves combat; client only sends actions |
| Multi-account farming | One arena attack per account per cooldown; arena Honor capped |
| Bots | Rate-limit RPCs (max 10/sec per user) |
| RMT (real-money trading) | No trading. No marketplace. |
| Account theft | Email + 2FA recommended for top-100 players |

## Telemetry

Log key events server-side. Build a Grafana dashboard around them.

- Gacha pulls (banner, result, pity counter at time of pull)
- Battle outcomes (win/loss, dungeon, turns used, time taken)
- Arena win rates by rank
- Player retention (D1, D7, D30)
- Stamina utilization (cap waste?)
- Currency flow (sources vs sinks)
- RPC error rates

## Hosting setup

### Production

```yaml
# docker-compose.yml (Nakama + Postgres on a single VPS)
version: '3'
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: <set in .env>
      POSTGRES_DB: nakama
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped

  nakama:
    image: heroiclabs/nakama:latest
    depends_on:
      - postgres
    environment:
      - DATABASE_URL=postgres://...
    ports:
      - "7349:7349"   # gRPC
      - "7350:7350"   # HTTP
      - "7351:7351"   # console
    restart: unless-stopped
    volumes:
      - ./modules:/nakama/data/modules   # TypeScript runtime

  backup:
    image: postgres:15
    command: >
      bash -c "while true; do pg_dump ...; sleep 86400; done"
    volumes:
      - ./backups:/backups
    restart: unless-stopped

volumes:
  postgres_data:
```

- Hetzner CCX13 (4 vCPU, 16GB RAM): ~€25/mo. Handles 10k MAU easily.
- Cloudflare in front for DDoS + cache.
- Cloudflare R2 for backups + asset CDN (free tier covers us).

### Staging

A second VPS (smallest size, ~$5/mo) running the same compose. Push changes
here first; promote to prod after validation.

## Deployment workflow

1. Develop server changes locally (Nakama runs in Docker on your dev machine).
2. Run integration tests against local Nakama.
3. Push to staging VPS via `docker-compose pull && docker-compose up -d`.
4. Validate on staging with a test account.
5. Promote to production.
6. Monitor logs + Grafana for 30 min post-deploy.

## What can wait until the game scales

Stuff you don't need until you have 10k+ players:

- Read replicas (Postgres replication).
- Redis caching layer.
- Multi-region deployment.
- Kubernetes / orchestration.
- Dedicated CDN beyond Cloudflare free.

Don't over-engineer. A single $25/mo VPS handles a small live game.

## What to learn before Phase 9

Before you start the server phase:

- TypeScript basics (you'll write server logic in TS).
- SQL fundamentals (the few queries we hand-write are basic SELECT/UPDATE).
- Docker / Docker Compose (one tutorial, an hour).
- Nakama docs — at minimum the "Storage Engine," "Authoritative Match,"
  "Groups," and "Leaderboards" sections.

Estimated learning time: 1–2 weekends if you're new to backends. Trivial if
you've done web work before.
