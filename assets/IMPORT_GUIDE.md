# Asset Import Guide

The actual workflow for getting third-party pixel art into Vaelthorn.
This is a reference doc — when you import a new pack, walk through it
and check the boxes for that pack.

---

## Phase 1.5b: Mana Seed Character Base

We're importing **Mana Seed Character Base** by Seliel the Shaper to
replace the placeholder Polygon2D sprites for Ember Knight and the
Training Slime.

### 1. Buy & download (5 min)

- Go to https://seliel-the-shaper.itch.io/character-base
- The base pack is **$15 USD**. Pay what you want above that if you
  feel like supporting the artist (they're great).
- Download the ZIP. macOS will save it to `~/Downloads`.

### 2. Unzip and find the sprites (3 min)

The pack contains:

- `character_base/` — naked character sprite sheets (Mana Seed's
  "base body" — male/female, lots of poses).
- Optional add-ons may include outfits, weapons, hair (depending
  on what version you got).

For Ember Knight (Phase 1.5b's only hero), we need:

- **One idle sprite sheet** (4–6 frame loop, side or 3/4 view).
- The "knight" or "fighter" outfit if available, otherwise the base
  body tinted gold.

### 3. Drop into the project (2 min)

Create the destination folder structure:

```
assets/sprites/manaseed/ember_knight/
    idle.png            # the chosen idle strip
    attack.png          # Phase 2+ (skip for now)
    hurt.png            # Phase 2+ (skip for now)
```

Just copy `idle.png` for now. Other animations land in Phase 2.

### 4. Import settings in Godot (3 min)

For every imported PNG:

1. Click the file in Godot's FileSystem panel.
2. Switch to the **Import** tab (top-left, next to "Scene").
3. Set:
   - **Filter:** `false` (we want nearest-neighbor / pixel-perfect)
   - **Mipmaps:** `false`
   - **Compression Mode:** `Lossless`
4. Click **Reimport**.

This must be done for every sprite asset, every time. There's a
project-wide setting to default this to "Nearest Neighbor" for pixel
art — set it once in **Project → Project Settings → Rendering →
Textures → Default Texture Filter** to `Nearest`. (Already done in
our `project.godot`.)

### 5. Wire it up (I'll do this in our session)

Once you have `assets/sprites/manaseed/ember_knight/idle.png` in
place, tell me and I'll:

- Create a `SpriteFrames` resource at `data/spriteframes/ember_knight.tres`.
- Configure the idle animation (frame count, FPS).
- Update `scenes/battle/unit.tscn` to swap the placeholder Polygon2D
  for an `AnimatedSprite2D`.
- Verify the battle still works end-to-end.

### 6. Slime / enemy art

The Training Slime isn't part of Mana Seed Character Base. Two options:

- **Quick fix:** keep the placeholder Polygon2D for slimes. We import
  enemy art from a separate creature pack later.
- **Bonus:** if you also grab a free creature pack (e.g. **0x72
  Dungeon Tileset II** — CC0, free) we can use a slime sprite from
  there. Tell me if you want to and I'll point at a specific file.

---

## Phase 1.5b: Pixel font (free, parallel to Mana Seed)

The UI currently uses Godot's default font. To match the pixel-art
aesthetic, install **m6x11** by Daniel Linssen:

1. Go to https://managore.itch.io/m6x11
2. "Pay what you want" — $0 is fine.
3. Download. Place the `.ttf` file at:

```
assets/fonts/m6x11.ttf
```

Tell me when it's there. I'll configure a project-wide Theme that
applies it to all Labels and Buttons in one pass.

---

## Phase 2+: Backgrounds

For battle backgrounds, the recommended pack is **Free Pixel Art
Backgrounds Vol 1–4** by Free Game Assets (free) or **ansimuz** packs
(also free). We won't import these until Phase 2 — for now the
layered ColorRects in `battle.tscn` give us a credible-enough
"battle stage" feel.

---

## License tracking

**Always** update `assets/CREDITS.md` when importing a third-party
asset. Pack name, author, source URL, license, where used. This
protects you legally and keeps the door open for future relationships
with the artists.
