# Asset Credits

Every imported asset (sprite pack, UI pack, font, SFX, music) goes here.

Update on import, not at release. Trivial discipline now prevents legal
headaches later.

## Sprites

| Asset | Author | Source | License | Used in |
|---|---|---|---|---|
| Mana Seed Character Base | Seliel the Shaper | [itch.io](https://seliel-the-shaper.itch.io/character-base) | Commercial use OK per pack license | All 6 hero `idle_sheet.png` + `combat_sheet.png` + `recovery_sheet.png` composites |
| Mana Seed Hairstyle Pack | Seliel the Shaper | [itch.io](https://seliel-the-shaper.itch.io/character-base) (hairstyle add-on) | Commercial use OK per pack license | Composited onto each hero sheet (spk2/flat/pon1/bob2/fro1 variants) |
| Mana Seed Sword & Shield Combat | Seliel the Shaper | [itch.io](https://seliel-the-shaper.itch.io/character-base) (combat add-on) | Commercial use OK per pack license | `combat_sheet.png` bodies + slash arc effect |
| 0x72 Dungeon Tileset II v1.7 | 0x72 (Robert) | [itch.io](https://0x72.itch.io/dungeontileset-ii) | CC0 (public domain) | `assets/sprites/0x72/goblin/idle_f{0..3}.png` (Training Goblin) |

**Note on Mana Seed composites:** every hero's sprite sheet
(`assets/sprites/manaseed/<hero>/{idle,combat,recovery}_sheet.png`) is a
composite of the Mana Seed base body, a hair file, and (for combat) the
pONE sword-and-shield body sheet — produced via ImageMagick. The
source PNGs themselves are not redistributed in this repo — only the
composited results for our specific heroes.

**Note on 0x72:** CC0 means we technically don't have to credit, but
crediting good free-asset authors is the right move. Specifically, the
goblin idle is `goblin_idle_anim_f{0..3}.png` from v1.7 of the pack.

## UI / Fonts / SFX / Music

| Asset | Author | Source | License | Used in |
|---|---|---|---|---|
| _none yet_ | — | — | — | — |

## License key

- **CC0:** Public domain. No attribution required (we credit anyway).
- **CC-BY:** Attribution required.
- **CC-BY-SA:** Attribution + share-alike.
- **itch.io paid:** Commercial use per the pack's license terms.
- **Other:** Read carefully before using.

## When in doubt

Don't import an asset whose license you can't articulate in one sentence.
