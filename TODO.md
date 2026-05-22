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

### VFX expansion (a series of small 10–30 min upgrades)

The current battle has: a single slash variant, red flash on hit, screen
shake, scale punch, position bump, color-coded damage popups (gold crit,
green lucky), and a fade on death. The list below is the natural growth
path. Each item is small + visible.

- [ ] **Per-skill slash variants** — Flame Slash uses Mana Seed's Slash
      2 (different arc shape), Shatter uses Thrust (jab effect), basic
      Strike keeps Slash 1. The pack ships all four.
- [ ] **Element-tinted slashes** — slash modulate matches the skill's
      element. Fire = orange, Water = cyan, etc. Same texture, different
      tint per cast.
- [ ] **Crit punch-up** — short screen flash + brief time-slow (Engine.
      time_scale = 0.5 for ~150 ms) + extra slash overlay. Crits should
      stop you cold for a beat.
- [ ] **Heal VFX** — green particle puff or upward shimmer when Mend
      lands. Right now you just see the `+amount` popup.
- [ ] **Buff VFX (Brace / Aegis)** — gold sparkle ring rising around the
      caster on apply. Status badge already exists; this is the moment-
      of-application flair.
- [ ] **Debuff VFX (Shatter)** — dark crack ripple on the target when
      DEF_DOWN lands. Complement the pink "-" status icon.
- [ ] **Burn ambient VFX** — small flame particles flickering above the
      burning unit each turn, on top of the orange B badge.
- [ ] **Ultimate cut-in (the big one)** — when an ult is used: dim the
      screen, zoom + scale the caster, hold for 300 ms, then resume.
      Standard BF / Star Rail "ult moment."
- [ ] **Hurt impact flash** — brief white screen-wide flash when a hero
      takes a critical hit. Sells the "ow" beyond the red tint.
- [ ] **Death effect** — small particle burst + brief screen darken when
      a unit dies, before the lying-down sprite settles.
- [ ] **Status icon pulse animations** — B icon pulses orange, - icon
      flickers magenta, etc. (Phase 5 polish.)

## Engineering hygiene

- [ ] Pre-commit hooks (gdformat, gdlint, content validation) — promised
      in Phase 0, still not installed.
- [ ] Refactor checkpoint after Phase 5 (per engineering doc).
