# TODO — Deferred Phases

Quick parking lot for everything we agreed to circle back to. Keep this
short and prune as items ship; don't let it bloat into a wishlist.

## Animation polish (continuing Phase 4)

- [ ] **4c — Armed idle (pONE2)**: sword + shield visible in the idle pose,
      not just bare hands. Composite pONE2 + p1 hair, swap idle frame.
      ~30 min.
- [ ] **4d — Self-skill animations**: Brace / Aegis / Mend play a defensive
      or channeling pose (pONE2 has stances we can use) instead of just
      the scale puff. ~30 min.
- [ ] **4f — More attack variants**: heroes currently all use Slash 1.
      Phase 7 (weapons) is where Stormarcher gets a bow, Priestess a
      staff, etc. Requires additional Mana Seed packs.

## Progression layer (Phase 3 — interrupted)

- [ ] **3c — Save/Load**: party choice + future state persists across
      runs. SaveManager is already stubbed since Phase 0 — needs wiring.
- [ ] **3d — Hero leveling**: XP from battles, level-up animation, stats
      scale per level. Per the leveling formula in docs/03-heroes.md.

## After progression

- [ ] **Phase 4 (roadmap) — Dungeon flow**: chapter map, stage select,
      stamina, drops, rewards.
- [ ] **Phase 5 — Progression depth**: ascension, promotion across tiers,
      hero merging, soul stones.
- [ ] **Phase 6 — Hero gacha**: summon banners + pity.
- [ ] **Phase 7 — Weapon system** (and unlocks bow/staff/etc. animations).
- [ ] **Phase 8 — itch.io single-player launch**.

## Polish / quality of life

- [ ] Sound effects pass (hit, crit, miss, ult, button click, ambient).
- [ ] Music (3-5 tracks: title, hub, battle, victory, defeat).
- [ ] Ultimate cinematic cut-in (current implementation is just a scale
      pulse; ideally a slow-mo + sprite zoom moment).
- [ ] More enemies (after 4e validates the enemy-sprite pipeline).
- [ ] Telemetry / crash reporter wiring.

## Engineering hygiene

- [ ] Pre-commit hooks (gdformat, gdlint, content validation) — promised
      in Phase 0, still not installed.
- [ ] Refactor checkpoint after Phase 5 (per engineering doc).
