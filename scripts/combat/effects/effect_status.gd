class_name EffectStatus extends Effect
## Applies a status to the target (Burn, Stun, ATK_UP, etc.).
##
## Chance is rolled against (1 - target.RES). The actual StatusEffectData
## is looked up by the battle scene via ContentRegistry.get_status(id),
## so this effect only needs the status id string.

@export var status_id: String = ""
@export var duration: int = 2
@export_range(0.0, 1.0, 0.01) var chance: float = 1.0
@export var power: float = 0.0


func apply(ctx: EffectContext) -> Dictionary:
	var resistance: float = float(ctx.target.get("res", 0.0))
	var actual_chance: float = chance * (1.0 - resistance)
	if not ctx.rng.chance(actual_chance):
		return {
			"kind": "status_resisted",
			"target_id": ctx.target_id,
			"status_id": status_id,
		}
	return {
		"kind": "status",
		"target_id": ctx.target_id,
		"status_id": status_id,
		"duration": duration,
		"power": power,
	}
