class_name SkillData extends Resource
## Skill template resource.
##
## One .tres per skill in data/skills/. Phase 1: direct damage / simple effects.
## Phase 2 introduces Effect Composition — at that point `effects: Array[Effect]`
## replaces the direct `power` / `element` fields here.

@export var id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""

@export_enum("ENEMY_SINGLE", "ENEMY_ALL", "ALLY_SINGLE", "ALLY_ALL", "SELF") var target_type: int = 0

## -1 = inherit from attacker. 0..5 = explicit element.
@export var element: int = -1

## Damage multiplier vs the formula's `attacker.atk`.
@export var power: float = 1.0

## Number of damage instances per cast (Phase 2 uses this with Effect atoms).
@export var hits: int = 1

## Turns of cooldown after use (Phase 2+).
@export var cooldown: int = 0
