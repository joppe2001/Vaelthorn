class_name SeededRNG extends RefCounted
## Deterministic RNG wrapper.
##
## One instance per domain (combat / gacha / gear-rolls). Never share.
## Combat seeds per battle for replays + server parity (Phase 9+).

var rng: RandomNumberGenerator


func _init(seed_value: int = -1) -> void:
	rng = RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()


func chance(p: float) -> bool:
	return rng.randf() < p


func range_float(low: float, high: float) -> float:
	return rng.randf_range(low, high)


func range_int(low: int, high: int) -> int:
	return rng.randi_range(low, high)


func pick(arr: Array):
	return arr[rng.randi() % arr.size()]
