class_name EffectDamage extends Effect
## Deals damage to the target via the shared Damage.compute() formula.
##
## Element resolution (in priority order):
##   1. element_override (>= 0): use this element
##   2. skill.element (>= 0): inherit from skill
##   3. attacker.element: inherit from attacker
##
## Hits are sequential; each hit rolls hit/dodge and crit independently.

@export var power_mult: float = 1.0
@export var hits: int = 1
@export var element_override: int = -1


func apply(ctx: EffectContext) -> Dictionary:
	var element := _resolve_element(ctx)

	var hit := Damage.is_hit(ctx.attacker, ctx.target, ctx.rng)
	if not hit:
		return {"kind": "miss", "target_id": ctx.target_id}

	var total_damage := 0
	var any_crit := false
	var any_lucky := false
	var elemental_mult := 1.0

	for _i in hits:
		var dmg: Dictionary = Damage.compute(ctx.attacker, ctx.target, power_mult, element, ctx.rng)
		total_damage += int(dmg.damage)
		if dmg.is_crit:
			any_crit = true
		if dmg.is_lucky:
			any_lucky = true
		elemental_mult = dmg.elemental

	return {
		"kind": "damage",
		"target_id": ctx.target_id,
		"damage": total_damage,
		"is_crit": any_crit,
		"is_lucky": any_lucky,
		"elemental_mult": elemental_mult,
	}


func _resolve_element(ctx: EffectContext) -> int:
	if element_override >= 0:
		return element_override
	if ctx.skill != null and ctx.skill.element >= 0:
		return ctx.skill.element
	return int(ctx.attacker.get("element", 0))
