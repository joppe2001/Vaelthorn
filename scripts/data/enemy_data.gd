class_name EnemyData extends Resource
## Enemy template resource.
##
## One .tres per enemy in data/enemies/. Loaded at startup by ContentRegistry.
## Enemies are simpler than heroes: no rarity ladder, no skill_ids array yet
## (Phase 1 uses a single `attack_power` value; Phase 2 adds proper skills).

@export var id: String = ""
@export var display_name: String = ""

@export_enum("FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK") var element: int = 0

@export_group("Stats")
@export var hp: int = 500
@export var atk: int = 80
@export var def: int = 30
@export var spd: int = 80
@export_range(0.0, 1.0, 0.01) var crit_rate: float = 0.05
@export var crit_dmg: float = 1.5
@export_range(0.0, 1.0, 0.01) var acc: float = 0.95
@export_range(0.0, 1.0, 0.01) var eva: float = 0.05
@export var luk: int = 20
@export_range(0.0, 1.0, 0.01) var res: float = 0.0

@export_group("Combat")
## Damage multiplier when this enemy attacks. Phase 2 replaces this with skill_ids.
@export var attack_power: float = 1.0

@export_group("Rewards")
@export var xp_reward: int = 50
@export var gold_reward: int = 100

@export_group("Visuals")
## Fallback color tint when no SpriteFrames are set (placeholder Polygon2D).
@export var sprite_color: Color = Color(0.53, 0.78, 0.6, 1.0)
## When set, the Unit shows an AnimatedSprite2D using these frames instead of
## the placeholder polygon. Same shape as HeroData.idle_frames — must contain
## an "idle" animation at minimum; "hurt" and "dead" are optional.
@export var idle_frames: SpriteFrames = null
## Integer scale for pixel-perfect rendering.
@export var sprite_scale: float = 4.0
## Y offset so the visual feet line up with the ground band.
@export var sprite_y_offset: float = -96.0
