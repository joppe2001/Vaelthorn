class_name Damage extends RefCounted
## Pure-function damage resolver.
##
## No node references, no signals, no engine globals — testable in isolation,
## server-portable (Phase 9+ ports this to TypeScript bit-for-bit and runs
## shared test vectors against both sides).
##
## Formula (from docs/02-combat.md):
##   base       = max(1, skill_power * ATK - DEF * 0.5)
##   elemental  = Elements.multiplier(attacker.element, target.element)
##   variance   = uniform(0.95, 1.05)
##   crit       = random() < attacker.crit_rate
##   crit_mult  = attacker.crit_dmg  if crit  else 1.0
##   lucky      = random() < attacker.luk / 1000.0
##   luk_mult   = 1.5  if lucky  else 1.0
##   damage     = floor(base * elemental * variance * crit_mult * luk_mult)

static func compute(
	attacker_stats: Dictionary,
	target_stats: Dictionary,
	skill_power: float,
	skill_element: int,
	rng: SeededRNG,
	force_crit: bool = false,
) -> Dictionary:
	var atk: float = float(attacker_stats.get("atk", 0))
	var def: float = float(target_stats.get("def", 0))

	var base: float = max(1.0, skill_power * atk - def * 0.5)
	var elemental: float = Elements.multiplier(skill_element, int(target_stats.get("element", 0)))
	var variance: float = rng.range_float(0.95, 1.05)

	var crit_rate: float = float(attacker_stats.get("crit_rate", 0.05))
	var is_crit: bool = force_crit or rng.chance(crit_rate)
	var crit_mult: float = float(attacker_stats.get("crit_dmg", 1.5)) if is_crit else 1.0

	var luk: int = int(attacker_stats.get("luk", 0))
	var is_lucky: bool = rng.chance(float(luk) / 1000.0)
	var luk_mult: float = 1.5 if is_lucky else 1.0

	var damage: int = int(floor(base * elemental * variance * crit_mult * luk_mult))
	if damage < 1:
		damage = 1

	return {
		"damage": damage,
		"is_crit": is_crit,
		"is_lucky": is_lucky,
		"elemental": elemental,
	}


static func is_hit(attacker_stats: Dictionary, target_stats: Dictionary, rng: SeededRNG) -> bool:
	var acc: float = float(attacker_stats.get("acc", 0.95))
	var eva: float = float(target_stats.get("eva", 0.05))
	var hit_chance: float = clamp(acc - eva, 0.05, 1.0)
	return rng.chance(hit_chance)
