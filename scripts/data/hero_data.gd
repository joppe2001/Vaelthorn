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

@export_group("Visuals (placeholder until sprite import)")
@export var sprite_color: Color = Color(0.97, 0.78, 0.31, 1.0)
