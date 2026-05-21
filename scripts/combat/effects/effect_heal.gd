class_name EffectHeal extends Effect
## Restores HP to the target. Heal amount = attacker.ATK * heal_mult.
##
## Phase 2a: no heal skills exist yet, but the atom is here so authors can
## compose heroes that lifesteal-on-hit or have self-heal ultimates without
## a code change later.

@export var heal_mult: float = 0.5


func apply(ctx: EffectContext) -> Dictionary:
	var amount: int = int(float(ctx.attacker.get("atk", 0)) * heal_mult)
	if amount < 1:
		amount = 1
	return {
		"kind": "heal",
		"target_id": ctx.target_id,
		"amount": amount,
	}
