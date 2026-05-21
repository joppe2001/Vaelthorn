# 05 — Screens

Every screen the player will ever see, with a text wireframe and the key
interactions. Build from this list, don't add screens off-cuff.

## Screen list

| # | Screen | Phase | Purpose |
|---|---|---|---|
| 1 | Title | 0 | Logo, "Press any key", settings access |
| 2 | Home / Hub | 0 | Central nav, daily summary |
| 3 | Hero Roster | 3 | Grid of all owned heroes |
| 4 | Hero Detail | 3 | Stats, skills, gear, ascend, level |
| 5 | Party Builder | 2 | Select 5 heroes for combat |
| 6 | Dungeon Map | 4 | Chapter / dungeon select |
| 7 | Stage Select | 4 | Stages within a chapter |
| 8 | Battle | 1 | Combat |
| 9 | Battle Results | 1 | Rewards, XP, drops |
| 10 | Summon (Gacha) | 6 | Banner select, pull, results |
| 11 | Inventory | 7 | Gear, items, materials |
| 12 | Shop | 7 | Gold / gem store |
| 13 | Quests | 7 | Daily / weekly tasks |
| 14 | Settings | 0 | Volume, language, save, credits |

## Wireframes

ASCII layouts. **Resolution baseline: 1280x720 viewport, 16:9.** Mobile-port
will be a separate task — for now design for landscape.

### 1. Title

```text
+------------------------------------------------------------+
|                                                            |
|                    PIXEL ARENA                             |
|                  [animated logo]                           |
|                                                            |
|                                                            |
|                  > Press any key <                         |
|                                                            |
|                                                            |
|                                            [settings icon] |
+------------------------------------------------------------+
```

### 2. Home / Hub

```text
+------------------------------------------------------------+
| Player Lv 42        Gold: 1.2M   Gems: 425    Stamina: 87/120 |
+------------------------------------------------------------+
|                                                            |
|     [Daily summary panel]            [Featured banner art] |
|     - 3 daily quests pending                               |
|     - Tower floor 47 ready                                 |
|     - Boss raid: 2 attempts left                           |
|                                                            |
+------------------------------------------------------------+
|  [Battle]  [Heroes]  [Summon]  [Inventory]  [Quests]       |
|  [Shop]    [Settings]                                      |
+------------------------------------------------------------+
```

The Hub is the player's launchpad. Show what's next; don't make them dig.

### 3. Hero Roster

```text
+------------------------------------------------------------+
| Heroes (47/120)        Filter: [Element v][Class v][Rarity v]|
+------------------------------------------------------------+
|  [H][H][H][H][H][H][H][H]                                  |
|  [H][H][H][H][H][H][H][H]                                  |
|  [H][H][H][H][H][H][H][H]                                  |
|  [H][H][H][H][H][H][H][H]                                  |
|                                                            |
|  H = hero card (portrait, name, rarity stars, level)       |
|  Hover: highlight; Click: open Hero Detail                 |
+------------------------------------------------------------+
| Sort: [Power v]   [Compare]   [Back]                       |
+------------------------------------------------------------+
```

### 4. Hero Detail

```text
+------------------------------------------------------------+
| < Back        Ember Knight  Lv 60/80  *4*                  |
+------------------------------------------------------------+
|   [Large portrait]      [Stats table]                      |
|   [Sprite preview      HP: 4,200                           |
|    animated idle]      ATK: 880                            |
|                        DEF: 410                            |
|                        SPD: 105                            |
|                        CRIT: 22% / 165%                    |
|                        LUK: 80                             |
|                                                            |
|   Lore: ...                                                |
+------------------------------------------------------------+
|   Skills:  [skill 1] [skill 2] [skill 3] [ULT]             |
|   Passive: "Ember Spark: On crit, apply Burn (2 turns)"    |
+------------------------------------------------------------+
|   Gear: [W][A][H][B][Ac][R]                                |
|   [Level Up]   [Ascend]   [Equip Gear]                     |
+------------------------------------------------------------+
```

Hovering a skill should show its full description, damage range, and animation
preview if possible.

### 5. Party Builder

```text
+------------------------------------------------------------+
| Build Party for: Chapter 3 - Stage 5                       |
+------------------------------------------------------------+
|  Your Party:                                               |
|  [slot 1][slot 2][slot 3][slot 4][slot 5]   Total Power: X |
|                                                            |
+------------------------------------------------------------+
|  Heroes (filter / sort same as roster):                    |
|  [H][H][H][H][H][H][H][H]                                  |
|  [H][H][H][H][H][H][H][H]                                  |
+------------------------------------------------------------+
|  Preset: [Save][Load 1][Load 2][Load 3]                    |
|  [Auto-Fill]   [Start Battle]   [Back]                     |
+------------------------------------------------------------+
```

**Auto-Fill** picks a balanced party for the upcoming fight (element matchup,
role coverage). Important QoL.

### 6. Dungeon Map

```text
+------------------------------------------------------------+
| World Map                                                  |
+------------------------------------------------------------+
|     [Chapter 1] -- [Chapter 2] -- [Chapter 3]              |
|        (done)        (done)        (current)               |
|                                                            |
|     [Daily Gold] [Daily XP] [Element Trial] [Tower]        |
|     [Boss Raid] [Event: Dragon Festival]                   |
+------------------------------------------------------------+
| Stamina: 87/120                                  [Back]    |
+------------------------------------------------------------+
```

### 7. Stage Select

```text
+------------------------------------------------------------+
| Chapter 3: The Smoldering Coast                            |
+------------------------------------------------------------+
|  [1*][2*][3*][3*][3*][2*][1*][?]                           |
|   ^selected                                                |
|                                                            |
|  Stage 3-5: The Lava Bridge                                |
|  Stamina: 12                                               |
|  Recommended Power: 45,000                                 |
|  Enemy preview: [fire enemy][fire enemy][fire boss]        |
|  Drop preview: [gold][xp][gear: Helmet]                    |
+------------------------------------------------------------+
| [Sweep x10] [Battle]                              [Back]   |
+------------------------------------------------------------+
```

**Sweep:** spend 10x stamina, skip the battle, get drops (only after 3-star
clear). Endgame QoL.

### 8. Battle (the main event)

```text
+------------------------------------------------------------+
| Round 4         [Pause]                            [Speed: 1x] |
+------------------------------------------------------------+
|                                                            |
|   Enemy team:                                              |
|   [E1 HP===]  [E2 HP====]  [E3 HP=]                        |
|                                                            |
|         [battle background art]                            |
|                                                            |
|   Your team:                                               |
|   [H1 HP====][H2 HP===][H3 HP==][H4 HP====][H5 HP=]        |
|   ULT:[||||][----][||||][||||][||]                         |
+------------------------------------------------------------+
| Turn order: H1 > E2 > H3 > E1 > H2 > ...                   |
+------------------------------------------------------------+
| Active: H1 Ember Knight                                    |
| [Basic][Skill1][Skill2][ULT]    Target: [tap an enemy]     |
+------------------------------------------------------------+
```

**Key visual feedback** (must-have for the game to feel right):

- Damage popups: float up + fade, color-coded (white normal, yellow crit,
  green heal, red status).
- Crit: screen shake 80ms + flash.
- Element advantage: target tinted with element color before hit.
- Ultimate: zoom-in cut-in, time slows for 1.5s, sprite enlarged.
- Status icons hover above unit (small pixel-art icons with turn count).
- Turn order bar updates in real-time as ATB ticks.

### 9. Battle Results

```text
+------------------------------------------------------------+
|             VICTORY!                                       |
|        Chapter 3 - Stage 5 cleared                         |
|        Turns: 7      Time: 1:24      Rating: 3 stars       |
+------------------------------------------------------------+
|  Rewards:                                                  |
|   +12,500 Gold                                             |
|   +850 XP each hero                                        |
|   +3 Gems (first clear)                                    |
|   Dropped: [gear] [evolution dust]                         |
|                                                            |
|  Hero XP gains:                                            |
|   Ember Knight  Lv 60 -> 61 (XP bar fills)                 |
|   Tideguard     Lv 58 -> 58                                |
+------------------------------------------------------------+
|  [Tap to continue]   [Replay]   [Next Stage]               |
+------------------------------------------------------------+
```

### 10. Summon (Gacha)

```text
+------------------------------------------------------------+
| Summon                                                     |
+------------------------------------------------------------+
|  Banners:                                                  |
|   [Standard]    [Featured: Galelancer]    [Element: Fire]  |
|     ^selected                                              |
|                                                            |
|  Banner art: [large featured hero portrait]                |
|  Rates: 5★ 5% / 4★ 25% / 3★ 70%                            |
|  Pity: 47 / 90 to guaranteed 5★                            |
|                                                            |
|  [Single Pull: 300 gems]   [10-Pull: 2,700 gems]           |
+------------------------------------------------------------+
| Gems: 4,250                                       [Back]   |
+------------------------------------------------------------+
```

Pull animation (must be skippable):
- Light beam shoots up.
- Color foreshadows rarity (white = 3★, blue = 4★, gold = 5★).
- Hero emerges with sprite, name, rarity stars.

### 11. Inventory

Tabs across the top: **Gear | Materials | Consumables | Soul Stones**.
Grid layout per tab. Standard inventory UX.

### 12. Shop

Categories: **Featured | Gems | Gold | Stamina | Materials | Bundles**.
Stamina refill, gold packs, etc. No real-money store in v1.

### 13. Quests

Tabs: **Daily | Weekly | Achievements**.
List with progress bar and claim button per quest.

### 14. Settings

Sliders for: Master volume, Music volume, SFX volume, Voice volume.
Toggles: Battle speed, Skip animations, Auto-target, Reduce motion.
Buttons: Save now, Load save, Reset progress (with confirmation), Credits.

## Visual hierarchy rules

- **Currencies always top-right** of every menu screen.
- **Back button always top-left.**
- **Primary action always bottom-right.**
- **Selected item always highlighted with element color.**
- **Numbers update with tween animations** (gold ticking up after a battle).

## Input map

| Input | Action |
|---|---|
| Mouse / touch | Universal — click/tap to interact |
| Enter | Confirm primary action |
| Esc | Back / cancel |
| 1–5 | Quick-select party slot in battle |
| Q W E | Skill 1, 2, ULT |
| Space | Pause battle / skip animation |
| Tab | Next target |

Controllers (Phase 9+): map D-pad to navigation, A/B to confirm/cancel, X/Y
to skill 1/2.
