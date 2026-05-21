# Vaelthorn

A turn-based pixel-art RPG in the lineage of **Brave Frontier**, **Idle Heroes**,
and **Honkai: Star Rail**. Party combat, hero collection, gacha, gear, weapons,
guilds, async PvP arena, co-op boss raids — and **F2P monetization built on a
fair-whale contract** ([12 — Monetization](docs/12-monetization.md)).

## Tech at a glance

- **Client engine:** Godot 4.3+ (GDScript)
- **Backend (Phase 9+):** Nakama (open-source game server) + TypeScript runtime + PostgreSQL
- **Target platforms (v1):** Windows, macOS, Linux — mobile-ready architecture
- **Art:** Free pixel-art asset packs, locked to a master palette
- **Hosting (online phases):** ~$10–20/mo VPS (Hetzner / DigitalOcean)
- **Payments:** Stripe (web) → App Store / Google Play (mobile later)
- **Save:** Local JSON in Phases 1–8 → server-authoritative from Phase 9 onward

## Release plan

Each release is a real product. We ship intermediate versions; we don't
disappear into a 2-year dev cave.

| Release | Phases | What ships | Time |
|---|---|---|---|
| **v1.0 — Single-player** | 0–8 | Battle, heroes, gear, weapons, gacha (gems earned), story chapters, hero merging. No IAP. | ~7–9 months part-time |
| **v2.0 — Online** | 9–10 | Cloud save, accounts, async PvP arena, leaderboards, **Stripe gem packs** | +5–6 months |
| **v3.0 — Social** | 11–12 | Guilds, chat, guild boss raids, **Monthly Pass** | +5–7 months |
| **v4.0 — Co-op + live ops** | 13–14 | Real-time co-op raids, **Season Pass**, content cadence | +5–7 months |

**Total to v4: ~22–26 months part-time.** First real launch (v1.0) in under a year.

## How this document is organized

| Doc | What's in it |
|---|---|
| [01 — Vision](docs/01-vision.md) | Pillars, references, scope reality |
| [02 — Combat](docs/02-combat.md) | Stats, damage formula, turn order, elements, status |
| [03 — Heroes](docs/03-heroes.md) | Hybrid rarity (named tiers × stars), classes, skills, ascension, promotion, awakening |
| [04 — Progression](docs/04-progression.md) | Dungeons, hero gacha, weapon gacha, gear, currencies |
| [05 — Screens](docs/05-screens.md) | Wireframes for every screen |
| [06 — Art](docs/06-art.md) | Asset packs, palette, sprite specs, animation timing |
| [07 — Tech](docs/07-tech.md) | Godot client project structure, Resources, save format |
| [08 — Roadmap](docs/08-roadmap.md) | All 14 phases with realistic timelines |
| [09 — Multiplayer](docs/09-multiplayer.md) | Async arena, guilds, guild raids, co-op raids |
| [10 — Server](docs/10-server.md) | Nakama, authoritative combat, anti-cheat, hosting |
| [11 — Engineering](docs/11-engineering.md) | **Read this.** Architecture rules, content pipeline, testing, perf budgets, gates |
| [12 — Monetization](docs/12-monetization.md) | **Read this.** F2P contract, gem packs, VIP, passes, anti-predatory rules |

## Status

| | |
|---|---|
| Current phase | 0 — Foundation (in progress) |
| Setup | Solo, part-time (~10 hrs/week) |
| Godot installed | Yes (4.3 LTS) |
| Git repo | https://github.com/joppe2001/Vaelthorn.git |
| Last updated | 2026-05-21 |

## Two-phase mental model

When working on Phases 1–8: **assume the game is offline.** Save to disk, no
accounts, no network, no IAP. Treat it like a complete game.

When working on Phases 9+: **the local save becomes a client cache.** Server
is source of truth. Combat is replayed server-side for validation. Cheating
becomes impossible. Real-money purchases go through Stripe + server validation.

Build the single-player game like it will ship that way — because v1.0 will.

## The F2P contract (full version in [12](docs/12-monetization.md))

- You can play forever without spending.
- You can collect every hero. Slowly.
- You can compete in PvP through smart play.
- You can clear every PvE encounter.
- You will not be reminded you should have spent more.

If a feature breaks this contract, the feature loses.
