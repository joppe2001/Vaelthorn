class_name HeroData extends Resource
## Hero template resource.
##
## One .tres per hero in data/heroes/. Loaded at startup by ContentRegistry.
## Indexed by `id`. Skills are referenced by ID (looked up via the registry),
## not embedded — keeps content loosely coupled.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var lore: String = ""

@export_enum("FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK") var element: int = 0
@export_enum("ATTACKER", "DEFENDER", "HEALER", "BUFFER", "DEBUFFER", "RANGER") var class_type: int = 0

@export_group("Base Stats (Lv 1, Common 1*)")
@export var base_hp: int = 1000
@export var base_atk: int = 100
@export var base_def: int = 50
@export var base_spd: int = 100
@export_range(0.0, 1.0, 0.01) var base_crit_rate: float = 0.05
@export var base_crit_dmg: float = 1.5
@export_range(0.0, 1.0, 0.01) var base_acc: float = 0.95
@export_range(0.0, 1.0, 0.01) var base_eva: float = 0.05
@export var base_luk: int = 50
@export_range(0.0, 1.0, 0.01) var base_res: float = 0.0

@export_group("Skills")
## Skill IDs in cast order. Look up via ContentRegistry.get_skill(id).
@export var skill_ids: PackedStringArray = PackedStringArray()
## Optional ultimate skill id.
@export var ultimate_id: String = ""
## Optional always-on passive id (Phase 2+).
@export var passive_id: String = ""

@export_group("Visuals")
## Fallback color tint when no SpriteFrames are set (placeholder Polygon2D).
@export var sprite_color: Color = Color(0.97, 0.78, 0.31, 1.0)
## Static front-facing portrait — used in roster cards, party builder, hero
## detail. Typically a 256x256 PNG cropped from the front idle pose (row 1
## col 1 of the Mana Seed sheet). Null = fallback to sprite_color rect.
@export var portrait: Texture2D = null
## When set, the Unit shows an AnimatedSprite2D using these frames instead of
## the Polygon2D placeholder. Leave null for entities without art yet.
@export var idle_frames: SpriteFrames = null
## Integer scale applied to the AnimatedSprite2D. Must be an integer for
## pixel-perfect rendering.
@export var sprite_scale: float = 4.0
## Y offset of the AnimatedSprite2D relative to the unit's feet (origin).
## Tune this per hero so the visual feet line up with the ground.
@export var sprite_y_offset: float = -96.0
