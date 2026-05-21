class_name SkillData extends Resource
## Skill template resource.
##
## Phase 2a migrated from monolithic power/element fields to Effect Composition.
## A skill is now a *list of Effect atoms* (Damage, Status, Heal, ...). The
## battle scene calls each effect's apply() and processes the results.
##
## See [docs/11-engineering.md#2-composable-effects-the-killer-pattern].

@export var id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""

@export_enum("ENEMY_SINGLE", "ENEMY_ALL", "ALLY_SINGLE", "ALLY_ALL", "SELF") var target_type: int = 0

## -1 = inherit from attacker. 0..5 = explicit element override for this skill.
## EffectDamage's element_override field can further override per-effect.
@export var element: int = -1

## Turns of cooldown after use (Phase 2b+ enforces this).
@export var cooldown: int = 0

## ATB cost (Phase 2c+ uses this when round-based is replaced with ATB).
@export var atb_cost: int = 100

## The skill's effect list. Order matters — they apply sequentially.
## Typical compositions:
##   [EffectDamage(power=1.0)]                         basic attack
##   [EffectDamage(power=2.0), EffectStatus("burn")]   damage + status
##   [EffectHeal(0.3)]                                 self-heal
@export var effects: Array[Effect] = []
