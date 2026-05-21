# 06 — Art

You're using free asset packs. This doc tells you which ones, how to combine
them coherently, and what rules keep the game looking like *one* game and not
a Frankenstein.

## Recommended asset packs

All of these are free or cheap (under $20) on itch.io / OpenGameArt. None
require attribution to be removed, but you should credit them in the in-game
Credits screen anyway — it's good karma and keeps the door open for the
artists' future work.

### Character sprites (heroes & enemies)

| Pack | Author | License | Why |
|---|---|---|---|
| **Tiny RPG Forest** | Pita | $5 itch.io | Clean 16x16 fantasy heroes, multi-frame animations |
| **Mana Seed Character Base** | Seliel the Shaper | $15 itch.io | Massive base + modular outfits, RPG-ready |
| **LPC Character Generator** | OpenGameArt (multiple) | CC-BY-SA | Web tool, infinite character combos |
| **0x72 Dungeon Tileset II** | 0x72 | CC0 | Heroes + monsters in 16x16 |
| **Pixel Fantasy RPG Icons** | Caz Wolf | $5 itch.io | Skill / item icons, hundreds of them |

### Backgrounds (battle scenes)

| Pack | Author | License | Why |
|---|---|---|---|
| **Free Pixel Art Backgrounds** | ansimuz | CC0 | Parallax-ready, multi-biome |
| **Pixel Art Backgrounds Vol 1–4** | Free Game Assets | Free | High variety |
| **Forest / Desert / Lava parallax** | Edermunizz | itch.io free | Strong layered parallax |

### UI

| Pack | Author | License | Why |
|---|---|---|---|
| **Free UI Pack** | Kenney.nl | CC0 | Buttons, panels, sliders — pixel-art ready |
| **9-Slice Pixel UI** | Penzilla | $3 itch.io | 9-patch panels for any resolution |
| **Pixel Fantasy UI** | Caz Wolf | $5 itch.io | Matches the icon pack above |

### SFX / Music

| Pack | Author | License | Why |
|---|---|---|---|
| **Kenney Audio Packs** | Kenney.nl | CC0 | Hit, miss, level-up, UI clicks |
| **Sonniss GDC Bundle** | Sonniss | Royalty-free | Annual bundle, AAA-grade SFX |
| **Free Music Archive** | various | various | Filter by license |
| **PlayOnLoop / OpenGameArt music** | various | various | Loops + stingers |

## Pick a master palette (critical)

The single biggest thing that makes asset packs look like one game vs. a mishmash
is **palette discipline**. Pick a master palette, then re-color any asset that
doesn't fit it.

### Recommended palettes

| Palette | Colors | Vibe |
|---|---|---|
| **Endesga 64** | 64 | Vibrant, modern indie |
| **AAP-64** | 64 | Soft, hand-painted feel |
| **PICO-8** | 16 | Distinctive, retro, limited |
| **Sweetie 16** | 16 | Pastel, friendly |
| **Resurrect 64** | 64 | Cinematic, slightly desaturated |

**Recommended for BF/IH style: Endesga 64.** Vibrant enough to sell elements
(fire reds, water blues, earth greens), wide enough to handle UI without
desaturation.

Download the palette `.hex` file and import it into Aseprite. Lock all art to
that palette. Use Aseprite's "Remap" feature to re-color non-matching assets.

## Sprite specifications

### Character sprites

- **Base size:** 32x32 pixels (works for both heroes and small enemies).
- **Boss size:** 64x64 or 96x96 for big enemies.
- **Anchor:** bottom-center pixel.
- **Facing:** right (mirror in code for enemies on the right side facing left).

### Animation frames

| Animation | Frame count | Loop? | Notes |
|---|---|---|---|
| Idle | 4 frames | Yes | 800ms per loop (200ms/frame). Subtle bob. |
| Attack | 6 frames | No | 500ms total: anticipate (2) + strike (1) + recover (3) |
| Hurt | 3 frames | No | 250ms total. Flash white on frame 1. |
| Ultimate cut-in | 8–12 frames | No | 1.5s, dramatic |
| Victory | 4 frames | Yes | Looped pose |
| Defeat | 3 frames | No | Fall, then static |
| Cast (channel) | 4 frames | Yes | Looped while channeling |

### Sprite naming convention

```text
assets/sprites/heroes/<hero_id>/
    idle.png        # horizontal strip, 4 frames
    attack.png      # horizontal strip, 6 frames
    hurt.png        # horizontal strip, 3 frames
    ult.png         # horizontal strip, 8-12 frames
    victory.png     # horizontal strip, 4 frames
    defeat.png      # horizontal strip, 3 frames
    cast.png        # horizontal strip, 4 frames (optional)
    portrait.png    # 64x64 portrait for menus
```

Strip layout (left to right, top-aligned). Godot's `SpriteFrames` resource
chunks these for you.

## Background spec

- **Base resolution:** 384x216 (16:9 at 1.5x native).
- **Display scale:** 3x → 1152x648 viewport.
- **Layers:** 3 parallax layers (back / mid / fore) for depth.
- **Scroll speed ratio:** back 0.2x, mid 0.5x, fore 1.0x.

Don't scroll during turn-based combat — it's distracting. Reserve parallax for
**Hub / Dungeon Map** screens.

## UI spec

- **Window scaling:** integer-multiple only (no half-pixels).
- **Font:** monogram pixel font (e.g. *Datalegreya*, *m5x7*, *Press Start 2P* —
  but only use Press Start 2P for headlines, it's too thick for body).
- **Font sizes:** 8px small / 12px body / 16px headers / 24px hero names.
- **9-slice panels** for any sized container (buttons, dialogs, tooltips).
- **Hover state:** brighten by 15%, no scale.
- **Press state:** brighten by 30%, offset 1px down.

## Color usage rules

| Use case | Color source |
|---|---|
| Fire effects | Endesga reds (#ff5b5b, #c84147) |
| Water effects | Endesga blues (#4d65b4, #6daefb) |
| Earth effects | Endesga greens / browns (#3f6e3a, #7b4f2b) |
| Wind effects | Endesga light cyans + whites |
| Light effects | Endesga yellows / cream + glow |
| Dark effects | Endesga purples + near-black |
| Crit damage | Yellow (#fed442) |
| Normal damage | White (#ffffff) |
| Heal | Green (#88c070) |
| Status DoT | Magenta (#cc4eaf) |
| Selected highlight | Cyan (#42caff) |

Lock these in code as constants — never paint UI by hand-picking colors at edit
time.

## Animation timing (juice)

| Event | Duration | Notes |
|---|---|---|
| Damage popup float | 600ms | Float up 24px + fade |
| Screen shake on crit | 80ms | Amplitude 4px |
| Hit flash | 100ms | White overlay 60% alpha |
| Element tint | 200ms | Tint before hit lands |
| Ultimate slow-mo | 1500ms | Time scale 0.3x |
| Victory zoom | 400ms | Scale 1.0 → 1.1 → 1.0 |
| Currency tick-up | 800ms | Use easing, not linear |
| Menu transitions | 250ms | Slide + fade |

## What NOT to do

- **Don't mix art styles.** No 8-bit (NES) sprites in the same scene as 16-bit
  (SNES) sprites. Pick one fidelity and stick.
- **Don't anti-alias pixel art.** Set Godot import to nearest-neighbor / no
  filter for every sprite. The pixel grid is the aesthetic.
- **Don't subpixel-scale.** Camera and sprite positions snap to integer pixels.
- **Don't mix font hinting styles.** Pixel fonts only, no smoothing.
- **Don't use stock effects (Unity / Godot particles) unless they fit pixel
  art.** Render particles in a low-res viewport and upscale.

## Credits file

Create `assets/CREDITS.md` from day 1 and update with every asset you import.
Include: pack name, author, source URL, license. This protects you and is
trivial to maintain if you do it incrementally.
