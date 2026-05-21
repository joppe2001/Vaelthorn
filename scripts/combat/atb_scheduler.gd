class_name ATBScheduler extends RefCounted
## Pure-function ATB (Active Time Battle) scheduler.
##
## Each unit's ATB gauge fills at a rate equal to its SPD per unit time.
## When a unit's ATB reaches 100, they act, then their ATB is reduced by
## the skill's atb_cost (default 100).
##
## next_actor(states) simulates one step:
##   1. Find which unit needs the LEAST time to fill to 100.
##   2. Advance ALL alive units' ATB by that amount.
##   3. Return the winning unit's id + the new state of every unit.
##
## predict_sequence(states, count) simulates `count` steps forward without
## mutating the input, returning the ordered list of actor ids. Used by the
## turn order indicator UI.
##
## State shape (one dict per unit):
##   {"id": String, "atb": float (0..100), "spd": float, "alive": bool}

const FULL_GAUGE := 100.0
const DEFAULT_ATB_COST := 100.0


## Compute who acts next + the resulting ATB state of every unit.
## Returns {} when no unit is alive + can fill.
static func next_actor(atb_states: Array) -> Dictionary:
	var best_idx: int = -1
	var best_time: float = INF
	for i in atb_states.size():
		var unit: Dictionary = atb_states[i]
		if not unit.get("alive", true):
			continue
		var spd: float = float(unit.get("spd", 0.0))
		if spd <= 0.0:
			continue
		var atb: float = float(unit.get("atb", 0.0))
		var t: float = (FULL_GAUGE - atb) / spd
		if t < best_time:
			best_time = t
			best_idx = i

	if best_idx < 0:
		return {}

	var new_states: Array = []
	for unit in atb_states:
		var new_unit: Dictionary = unit.duplicate(true)
		if unit.get("alive", true) and float(unit.get("spd", 0.0)) > 0.0:
			new_unit["atb"] = float(unit.get("atb", 0.0)) + float(unit.get("spd", 0.0)) * best_time
		new_states.append(new_unit)

	return {
		"actor_id": atb_states[best_idx].id,
		"time_elapsed": best_time,
		"new_states": new_states,
	}


## Simulate `count` actions forward without mutating input.
## Returns an ordered list of actor ids. Uses DEFAULT_ATB_COST to deduct
## after each action; the real battle scene uses the per-skill atb_cost when
## actually applying.
static func predict_sequence(atb_states: Array, count: int) -> Array:
	var states: Array = []
	for s in atb_states:
		states.append(s.duplicate(true))

	var sequence: Array = []
	for _i in count:
		var step: Dictionary = next_actor(states)
		if step.is_empty():
			break
		sequence.append(step.actor_id)
		states = step.new_states
		for state in states:
			if state.id == step.actor_id:
				state["atb"] = max(0.0, float(state.atb) - DEFAULT_ATB_COST)
				break
	return sequence


## Helper: deduct an ATB cost from one actor in-place. Use after applying a
## real skill that has a non-default atb_cost.
static func deduct(atb_states: Array, actor_id: String, cost: float) -> void:
	for state in atb_states:
		if state.id == actor_id:
			state["atb"] = max(0.0, float(state.atb) - cost)
			return
