class_name Elements extends RefCounted
## 6x6 element matchup table — pure data, no node deps.
##
## TABLE[attacker][target] -> damage multiplier.
##   Fire > Wind > Earth > Water > Fire    (1.5x advantage, 0.5x reverse)
##   Light <-> Dark                        (2.0x both ways)
##   Same element / neutral                (1.0x)

const FIRE := 0
const WATER := 1
const EARTH := 2
const WIND := 3
const LIGHT := 4
const DARK := 5

const TABLE := [
	# attacker:     F    W    E    Wi   L    D
	[              1.0, 0.5, 1.0, 1.5, 1.0, 1.0],  # FIRE
	[              1.5, 1.0, 0.5, 1.0, 1.0, 1.0],  # WATER
	[              1.0, 1.5, 1.0, 0.5, 1.0, 1.0],  # EARTH
	[              0.5, 1.0, 1.5, 1.0, 1.0, 1.0],  # WIND
	[              1.0, 1.0, 1.0, 1.0, 1.0, 2.0],  # LIGHT
	[              1.0, 1.0, 1.0, 1.0, 2.0, 1.0],  # DARK
]


static func multiplier(attacker_element: int, target_element: int) -> float:
	if attacker_element < 0 or attacker_element > 5:
		return 1.0
	if target_element < 0 or target_element > 5:
		return 1.0
	return TABLE[attacker_element][target_element]


static func name_of(element: int) -> String:
	match element:
		FIRE:  return "Fire"
		WATER: return "Water"
		EARTH: return "Earth"
		WIND:  return "Wind"
		LIGHT: return "Light"
		DARK:  return "Dark"
		_:     return "Neutral"
