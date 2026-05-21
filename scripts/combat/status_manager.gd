class_name StatusManager extends RefCounted
## Per-unit tracker for active statuses.
##
## Each entry: { remaining_turns: int, power: float, data: StatusEffectData }
## Pure data + logic, no node refs. Battle scene renders the icons.

var active: Dictionary = {}


## Add or refresh a status. If already present, take the longer remaining duration.
func add(status_id: String, duration: int, power: float, data: StatusEffectData) -> void:
	if active.has(status_id):
		var existing = active[status_id]
		existing.remaining_turns = max(existing.remaining_turns, duration)
		existing.power = max(existing.power, power)
	else:
		active[status_id] = {
			"remaining_turns": duration,
			"power": power,
			"data": data,
		}


func remove(status_id: String) -> void:
	active.erase(status_id)


func has(status_id: String) -> bool:
	return active.has(status_id)


func is_stunned() -> bool:
	for s in active.values():
		if s.data.skip_turn:
			return true
	return false


## Aggregate stat multiplier from all active status modifiers.
## Result is clamped to [0.0, inf). Returns 1.0 if no relevant modifiers.
##
## stat_key: "atk" | "def" | "spd" | "acc" | "eva" | "crit_rate"
func get_stat_multiplier(stat_key: String) -> float:
	var mult: float = 1.0
	for s in active.values():
		var data: StatusEffectData = s.data
		var matches: bool = false
		match data.modifier_kind:
			StatusEffectData.ModifierKind.ATK_PCT:
				matches = stat_key == "atk"
			StatusEffectData.ModifierKind.DEF_PCT:
				matches = stat_key == "def"
			StatusEffectData.ModifierKind.SPD_PCT:
				matches = stat_key == "spd"
			StatusEffectData.ModifierKind.ACC_PCT:
				matches = stat_key == "acc"
			StatusEffectData.ModifierKind.EVA_PCT:
				matches = stat_key == "eva"
			StatusEffectData.ModifierKind.CRIT_RATE_PCT:
				matches = stat_key == "crit_rate"
		if matches:
			mult += data.modifier_amount / 100.0
	return max(0.0, mult)


func all_ids() -> Array:
	return active.keys()


func remaining_turns(status_id: String) -> int:
	if not active.has(status_id):
		return 0
	return active[status_id].remaining_turns


## Tick all active statuses. Returns an array of result dicts:
##   {"kind": "tick_damage", "status_id": str, "amount": int}
##   {"kind": "status_expired", "status_id": str}
##
## Caller (battle scene) applies HP changes and updates icons.
func tick_end_of_turn(unit_stats: Dictionary) -> Array:
	var results: Array = []
	var to_remove: Array = []

	for status_id in active:
		var s = active[status_id]
		var data: StatusEffectData = s.data

		match data.tick_kind:
			StatusEffectData.TickKind.DOT_PERCENT_MAX_HP:
				var max_hp: int = int(unit_stats.get("hp", 100))
				var dmg: int = int(float(max_hp) * (data.tick_amount / 100.0))
				if dmg < 1:
					dmg = 1
				results.append({
					"kind": "tick_damage",
					"status_id": status_id,
					"amount": dmg,
				})
			StatusEffectData.TickKind.DOT_FLAT:
				results.append({
					"kind": "tick_damage",
					"status_id": status_id,
					"amount": int(data.tick_amount),
				})

		s.remaining_turns -= 1
		if s.remaining_turns <= 0:
			to_remove.append(status_id)

	for sid in to_remove:
		active.erase(sid)
		results.append({"kind": "status_expired", "status_id": sid})

	return results
