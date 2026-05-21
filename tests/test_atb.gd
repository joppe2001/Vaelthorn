extends Node
## Phase 2c ATB scheduler tests.
## Open tests/test_atb.tscn and press F6.

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	print("=== Vaelthorn ATB Tests ===")
	_test_faster_unit_acts_first()
	_test_equal_speed_first_index_wins()
	_test_advance_after_action_resets_actor()
	_test_dead_unit_skipped()
	_test_zero_speed_skipped()
	_test_sequence_prediction_alternates_close_speeds()
	_test_sequence_prediction_fast_unit_more_turns()
	_test_deduct_helper()

	print("")
	print("=== %d passed, %d failed ===" % [_passed, _failed])
	for f in _failures:
		print("  FAIL: ", f)
	if _failed == 0:
		print("ALL GREEN")
	else:
		push_error("TEST FAILURES")


func _assert(condition: bool, name: String) -> void:
	if condition:
		_passed += 1
		print("  PASS  " + name)
	else:
		_failed += 1
		_failures.append(name)
		push_error("[test] FAIL: " + name)


func _state(id: String, atb: float, spd: float, alive: bool = true) -> Dictionary:
	return {"id": id, "atb": atb, "spd": spd, "alive": alive}


# ─── next_actor ──────────────────────────────────────────────────────

func _test_faster_unit_acts_first() -> void:
	print("\n[next_actor faster first]")
	var states := [
		_state("a", 0, 100),
		_state("b", 0, 50),
	]
	var step: Dictionary = ATBScheduler.next_actor(states)
	_assert(step.actor_id == "a", "faster SPD (100 vs 50) acts first (got %s)" % str(step.actor_id))
	_assert(abs(step.time_elapsed - 1.0) < 0.001, "time_elapsed = 1.0 (got %.3f)" % step.time_elapsed)
	for new_unit in step.new_states:
		if new_unit.id == "a":
			_assert(new_unit.atb == 100.0, "a's ATB at 100 (got %.1f)" % new_unit.atb)
		else:
			_assert(new_unit.atb == 50.0, "b's ATB at 50 (got %.1f)" % new_unit.atb)


func _test_equal_speed_first_index_wins() -> void:
	print("\n[next_actor tie -> first index]")
	var states := [
		_state("a", 0, 100),
		_state("b", 0, 100),
	]
	var step: Dictionary = ATBScheduler.next_actor(states)
	_assert(step.actor_id == "a", "ties go to first registered (got %s)" % str(step.actor_id))


func _test_advance_after_action_resets_actor() -> void:
	print("\n[advance + deduct]")
	# Simulate: a acts (cost 100), b's ATB then advances to ~50% on next tick
	var states := [
		_state("a", 0, 100),
		_state("b", 0, 100),
	]
	var step1: Dictionary = ATBScheduler.next_actor(states)
	# After step 1: a at 100, b at 100 (tied). Deduct 100 from a.
	ATBScheduler.deduct(step1.new_states, "a", 100.0)
	for new_unit in step1.new_states:
		if new_unit.id == "a":
			_assert(new_unit.atb == 0.0, "a back to 0 after deduct (got %.1f)" % new_unit.atb)
		else:
			_assert(new_unit.atb == 100.0, "b stays at 100 (got %.1f)" % new_unit.atb)
	# Next tick: b has 100, a has 0; b acts immediately
	var step2: Dictionary = ATBScheduler.next_actor(step1.new_states)
	_assert(step2.actor_id == "b", "b acts next (got %s)" % str(step2.actor_id))
	_assert(step2.time_elapsed == 0.0, "no time needed since b already at 100 (got %.3f)" % step2.time_elapsed)


func _test_dead_unit_skipped() -> void:
	print("\n[dead skipped]")
	var states := [
		_state("a", 0, 100, false),
		_state("b", 0, 50),
	]
	var step: Dictionary = ATBScheduler.next_actor(states)
	_assert(step.actor_id == "b", "dead 'a' skipped, 'b' acts (got %s)" % str(step.actor_id))


func _test_zero_speed_skipped() -> void:
	print("\n[zero speed skipped]")
	var states := [
		_state("a", 0, 0),
		_state("b", 0, 50),
	]
	var step: Dictionary = ATBScheduler.next_actor(states)
	_assert(step.actor_id == "b", "0 SPD skipped (got %s)" % str(step.actor_id))


# ─── predict_sequence ────────────────────────────────────────────────

func _test_sequence_prediction_alternates_close_speeds() -> void:
	print("\n[predict alternation]")
	# Close speeds — expect roughly alternating
	var states := [
		_state("a", 0, 100),
		_state("b", 0, 100),
	]
	var seq: Array = ATBScheduler.predict_sequence(states, 6)
	_assert(seq.size() == 6, "sequence length 6 (got %d)" % seq.size())
	# With equal speeds and tie-go-to-first, pattern is a,b,a,b,...
	var alternates_ok := true
	for i in 6:
		var expected = "a" if (i % 2 == 0) else "b"
		if seq[i] != expected:
			alternates_ok = false; break
	_assert(alternates_ok, "equal SPD alternates a,b,a,b,a,b (got %s)" % str(seq))


func _test_sequence_prediction_fast_unit_more_turns() -> void:
	print("\n[predict speed advantage]")
	# Player 2x faster than enemy — over many turns player should outpace
	var states := [
		_state("p", 0, 100),
		_state("e", 0, 50),
	]
	var seq: Array = ATBScheduler.predict_sequence(states, 10)
	var p_count := 0
	var e_count := 0
	for actor in seq:
		if actor == "p": p_count += 1
		else: e_count += 1
	_assert(p_count > e_count, "faster unit gets more turns (p=%d, e=%d)" % [p_count, e_count])
	# 2:1 ratio should give roughly 6-7 player turns out of 10
	_assert(p_count >= 6 and p_count <= 7, "2x speed -> ~6-7 of 10 turns (got %d)" % p_count)


# ─── deduct ──────────────────────────────────────────────────────────

func _test_deduct_helper() -> void:
	print("\n[deduct helper]")
	var states := [_state("a", 80, 50), _state("b", 30, 50)]
	ATBScheduler.deduct(states, "a", 100.0)
	_assert(states[0].atb == 0.0, "deduct clamps to 0 (got %.1f)" % states[0].atb)
	_assert(states[1].atb == 30.0, "other units untouched")
