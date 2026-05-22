# TODO — Deferred Phases

Quick parking lot for everything we agreed to circle back to. Keep this
short and prune as items ship; don't let it bloat into a wishlist.

## Animation polish (continuing Phase 4)

- [x] **4c — Armed idle (pONE2)**: shipped. Sword + shield + pose-aligned
      hair composited from native pONE2/pONE3 layers across all 6 heroes
      (armed_idle / combat / recovery sheets).
- [x] **4d — Self-skill animations**: shipped. Brace/Aegis play the east-
      facing crouch pose, Mend plays the upright guard / channel pose,
      held briefly before the buff/heal lands.
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
- [x] **Element-tinted slashes** — shipped. Slash modulate driven by
      ELEMENT_TINT[skill.element], with attacker.element as the inherit
      fallback. FIRE=orange-red, WATER=cyan, EARTH=amber, WIND=pale
      green, LIGHT=yellow, DARK=purple.
- [x] **Element burst VFX** — shipped. Real pixel-art bursts from
      Pimen's spell packs spawn on top of the slash for FIRE / WATER /
      EARTH / WIND. LIGHT and DARK still fall back to tint-only until
      we source packs for them.
- [x] **Buff/Debuff VFX swapped to pixel art** — replaced the earlier
      code-driven gold ring + jagged spokes with Pimen sprite sheets:
      buff = shield rising, debuff = skull pierced by arrow.
- [x] **Crit punch-up** — shipped. Engine.time_scale = 0.4 for ~120ms
      wall time + amplified camera shake (12→14, 0.22→0.24).
      Re-entrancy guard prevents AoE multi-crits from leaving
      time_scale stuck. (Initial pass included a white screen flash;
      removed by request — the slow-mo + shake combo is enough.)
- [x] **Heal VFX** — shipped. Green expanding glow + 7 rising shimmer
      motes on the target when Mend (or any heal result) lands.
- [x] **Buff VFX (Brace / Aegis)** — shipped. Two-pulse gold ring + 10
      diamond sparkles radiating from the caster when a positive
      modifier status applies.
- [x] **Debuff VFX (Shatter)** — shipped. Jagged dark cracked rings +
      6 spokes shooting outward when a negative-modifier / DoT / stun
      status applies.
- [x] **Burn ambient VFX** — shipped. Looping 3-frame flame
      (assets/sprites/vfx/elements/fire_burst.png frames 1-3) parented
      to the unit so it follows through dashes. Spawned on add_status
      ("burn"), freed on remove_status / death.
- [x] **Death effect** — shipped. Code-driven soul particles (white/
      grey Polygon2D squares) drift up and fade ~0.95s before the
      lying-down sprite settles. Spawned on the unit's parent so the
      particles outlive the dying unit's fade.
- [x] **Ultimate cut-in (the big one)** — shipped. Dim overlay + slanted
      accent stripe + caster/ult banner that slides in, holds ~260ms,
      then fades. Caster also gets a bigger pre-swing pulse after the
      cut-in clears.
- [ ] **Hurt impact flash** — brief white screen-wide flash when a hero
      takes a critical hit. Sells the "ow" beyond the red tint.
- [ ] **Death effect** — small particle burst + brief screen darken when
      a unit dies, before the lying-down sprite settles.
- [x] **Status icon pulse animations** — shipped. Subtle ~1.4s scale
      cycle (1.0 → 1.06 → 1.0) on every status badge so they read as
      alive, not pasted. Tween auto-loops; queue_free kills it with
      the icon when the status expires.

## Engineering hygiene

- [ ] Pre-commit hooks (gdformat, gdlint, content validation) — promised
      in Phase 0, still not installed.
- [ ] Refactor checkpoint after Phase 5 (per engineering doc).
- [x] Unit anchor system — `Unit.get_anchor(&"feet"/"center"/"head"/
      "over_head"/"above")` so VFX/popups don't hardcode pixel offsets.
      Auto-sizes for 64px heroes and 16px enemies.
