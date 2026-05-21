# 01 — Vision

## Pillars

Five things that must be true for the game to feel right. Every design decision
should support at least one of these — and never contradict them.

1. **Combat is a puzzle, not a stat-check.**
   Crits, elements, turn order, and luck procs should make every fight feel
   tense even when you have a level advantage. The wrong skill at the wrong
   time should cost you.

2. **Every hero has identity.**
   No two heroes feel the same. Sprite, skill kit, role, and passive all
   reinforce a clear archetype. Players should have favorites within an hour.

3. **Pixel art with juice.**
   Hits land with screen shake, damage popups, palette flashes, and SFX.
   The art is simple — the *feedback* is rich.

4. **Sessions respect player time.**
   A satisfying combat round in under 60 seconds. A dungeon stage in under 5
   minutes. A play session in under 30 minutes — but rewarding if you stay.

5. **Desktop polish, mobile-ready architecture.**
   Build for keyboard + mouse first, but never paint ourselves into a corner.
   Touch input, portrait layouts, and short sessions are first-class concerns.

## Reference games

| Game | What we steal | What we don't |
|---|---|---|
| **Brave Frontier** | BB / Ultimate gauge, party of 5+1, elemental triangle, sprite style | Predatory monetization, dated UX |
| **Idle Heroes** | Rarity tiers, ascension via dupes, hero classes | Heavy idle/AFK loop, autoplay-first design |
| **Octopath Traveler** | Break / weakness system inspiration | 3D HD-2D scope |
| **Honkai: Star Rail** | Turn-based UX juice, ultimate cut-ins, modern feel | Voice acting / 3D budget |
| **Live A Live (2022 remake)** | Sprite work, battle juice, animation timing | Grid combat |
| **Chrono Trigger** | Clean turn-based pacing, ATB | Linear story scope |

## Target experience

Imagine the player's first 30 minutes:

1. **0–2 min:** Title screen → quick tutorial battle (1v1). They learn turn
   order, basic attack, and one skill. They get a clean win.
2. **2–10 min:** First chapter, 3 stages. Party grows to 3 heroes. They get
   their first elemental advantage moment ("oh, fire melts wind").
3. **10–15 min:** First crit, first lucky proc. Damage popup pops bigger. SFX
   sells the moment.
4. **15–20 min:** First summon. Gacha animation. They get a 3* hero.
5. **20–30 min:** They start customizing their party. They look at stats. They
   feel ownership.

If any one of these moments fails to land, we have work to do.

## Scope honesty

A full BF/IH clone has:

- ~50+ heroes (each with unique sprites, skills, passives)
- ~5 dungeon types
- Gacha + pity + currencies
- Gear with set bonuses
- Daily / weekly content
- Story chapters
- A tower / arena
- Cross-platform builds with cloud save

This is **12–18 months part-time** for a solo dev. The roadmap is built around
that reality — each phase ends with something playable, and the early phases
deliver the combat core that's worth playing on its own.

**If you only ever ship Phase 2 (party combat with elements + crits), you have
a real game.** Phases 3+ are the genre-defining layers on top.

## Anti-pillars (what we are *not*)

- **Not an idle game.** Active battle is the core loop. No auto-battle in v1.
- **Not real-time.** Combat is turn-based. No reflex pressure.
- **Not a roguelike.** Runs are not procedurally generated. Content is authored.
- **Not 3D.** Pixel art only. Even UI is pixel-style.
- **Not predatory F2P.** Vaelthorn is monetized — gem packs, VIP, Monthly
  Pass, Season Pass — but built on a fair-whale contract: no hero or weapon
  is gated behind real money, no FOMO timer pressure, no nested gacha.
  Full rules in [12 — Monetization](12-monetization.md).
