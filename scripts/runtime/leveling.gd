class_name Leveling extends RefCounted
## Pure leveling math. No state, no side effects — every function takes
## its inputs and returns the answer. Wired up from SaveManager (which
## owns the persisted xp/level dict) and battle.gd (awards XP at battle
## end + scales stats at runtime).
##
## Formulas come from docs/03-heroes.md:
##
##   xp_for_level(L)  =  floor(50 * L^1.7)         delta to reach L from L-1
##   stat(L)          =  base * (1 + 0.04*(L-1) + 0.001*(L-1)^2)
##
## Tier and star multipliers are NOT applied yet — they need the
## ascension system (Phase 5). Until then, every hero is treated as
## Common 1★ for stat math.

const DEFAULT_MAX_LEVEL := 100


## XP cost to *reach* the given level from the previous one. Level 1
## costs 0 (you start there); level 2 costs floor(50 * 2^1.7) = 162; etc.
static func xp_for_level(level: int) -> int:
	if level <= 1:
		return 0
	return int(floor(50.0 * pow(float(level), 1.7)))


## Total XP accumulated to reach (but not exceed) the given level.
static func total_xp_for_level(level: int) -> int:
	var total := 0
	for L in range(2, level + 1):
		total += xp_for_level(L)
	return total


## Inverse of total_xp_for_level: given how much XP a hero has
## collected, return the highest level they qualify for.
static func level_from_total_xp(total_xp: int, max_level: int = DEFAULT_MAX_LEVEL) -> int:
	var level := 1
	var spent := 0
	while level < max_level:
		var cost := xp_for_level(level + 1)
		if spent + cost > total_xp:
			break
		spent += cost
		level += 1
	return level


## XP banked into the current level — for the "XP bar" UI.
static func xp_into_current_level(total_xp: int, level: int) -> int:
	return total_xp - total_xp_for_level(level)


## XP needed to reach the next level from where the hero currently
## sits — i.e. the denominator of the XP bar.
static func xp_to_next_level(level: int) -> int:
	return xp_for_level(level + 1)


## Apply the per-level multiplier to a base stat. Floors the result so
## stats stay integers (no half-points).
static func stat_at_level(base_stat: int, level: int) -> int:
	if level <= 1:
		return base_stat
	var l_minus_1: float = float(level - 1)
	var mult: float = 1.0 + 0.04 * l_minus_1 + 0.001 * l_minus_1 * l_minus_1
	return int(floor(float(base_stat) * mult))


## Convenience: float multiplier without the floor, for stats that
## live as floats (crit_rate, acc, etc.).
static func float_stat_at_level(base_stat: float, level: int) -> float:
	if level <= 1:
		return base_stat
	var l_minus_1: float = float(level - 1)
	var mult: float = 1.0 + 0.04 * l_minus_1 + 0.001 * l_minus_1 * l_minus_1
	return base_stat * mult
