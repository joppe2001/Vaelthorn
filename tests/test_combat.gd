extends Node
## Phase 1 standalone test runner.
##
## Open `tests/test_combat.tscn` and press F6 to run.
## Phase 1b installs `gut` (Godot Unit Test) from the Asset Library and
## these assertions get migrated to proper gut tests.

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	print("=== Vaelthorn Test Runner ===")
	_test_element_table()
	_test_damage_basics()
	_test_damage_floor()
	_test_crit()
	_test_seeded_rng_determinism()
	_test_content_loaded()

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


# ─── Element table ───────────────────────────────────────────────────

func _test_element_table() -> void:
	print("\n[element table]")
	_assert(Elements.multiplier(Elements.FIRE, Elements.FIRE) == 1.0, "Fire vs Fire = 1.0")
	_assert(Elements.multiplier(Elements.FIRE, Elements.WIND) == 1.5, "Fire vs Wind = 1.5")
	_assert(Elements.multiplier(Elements.WIND, Elements.FIRE) == 0.5, "Wind vs Fire = 0.5")
	_assert(Elements.multiplier(Elements.WATER, Elements.FIRE) == 1.5, "Water vs Fire = 1.5")
	_assert(Elements.multiplier(Elements.EARTH, Elements.WATER) == 1.5, "Earth vs Water = 1.5")
	_assert(Elements.multiplier(Elements.LIGHT, Elements.DARK) == 2.0, "Light vs Dark = 2.0")
	_assert(Elements.multiplier(Elements.DARK, Elements.LIGHT) == 2.0, "Dark vs Light = 2.0")
	_assert(Elements.multiplier(Elements.FIRE, Elements.LIGHT) == 1.0, "Fire vs Light = 1.0 (neutral)")


# ─── Damage formula ──────────────────────────────────────────────────

func _test_damage_basics() -> void:
	print("\n[damage basics]")
	var rng := SeededRNG.new(12345)
	var attacker := {"atk": 100, "crit_rate": 0.0, "crit_dmg": 1.5, "luk": 0, "element": 0, "def": 0}
	var target := {"def": 20, "element": Elements.WATER}
	# base = max(1, 1.0 * 100 - 20*0.5) = 90
	# elemental: Fire vs Water = 0.5
	# variance ~ 0.95-1.05
	# expected damage: ~42-48
	var result := Damage.compute(attacker, target, 1.0, Elements.FIRE, rng)
	_assert(result.damage >= 40 and result.damage <= 50, "Fire vs Water dmg in [40,50] (got %d)" % result.damage)
	_assert(not result.is_crit, "0%% crit_rate => no crit")
	_assert(not result.is_lucky, "0 LUK => no lucky")


func _test_damage_floor() -> void:
	print("\n[damage floor]")
	var rng := SeededRNG.new(99)
	var weak := {"atk": 1, "crit_rate": 0.0, "crit_dmg": 1.5, "luk": 0, "element": 0, "def": 0}
	var tank := {"def": 99999, "element": 0}
	var result := Damage.compute(weak, tank, 1.0, Elements.FIRE, rng)
	_assert(result.damage >= 1, "damage >= 1 even vs infinite DEF (got %d)" % result.damage)


func _test_crit() -> void:
	print("\n[crit]")
	var rng := SeededRNG.new(42)
	var attacker := {"atk": 100, "crit_rate": 1.0, "crit_dmg": 2.0, "luk": 0, "element": 0, "def": 0}
	var target := {"def": 0, "element": 0}
	var result := Damage.compute(attacker, target, 1.0, Elements.FIRE, rng)
	_assert(result.is_crit, "100%% crit_rate always crits")
	# base 100, elem 1.0, variance ~1.0, crit_mult 2.0 -> ~190-210
	_assert(result.damage >= 180 and result.damage <= 220, "crit dmg around 200 (got %d)" % result.damage)


# ─── Determinism ─────────────────────────────────────────────────────

func _test_seeded_rng_determinism() -> void:
	print("\n[determinism]")
	var rng_a := SeededRNG.new(777)
	var rng_b := SeededRNG.new(777)
	var stats := {"atk": 100, "crit_rate": 0.5, "crit_dmg": 1.5, "luk": 100, "element": 0, "def": 50}
	var target := {"def": 50, "element": 1}
	var a := Damage.compute(stats, target, 1.5, Elements.FIRE, rng_a)
	var b := Damage.compute(stats, target, 1.5, Elements.FIRE, rng_b)
	_assert(a.damage == b.damage, "same seed -> same damage (got %d vs %d)" % [a.damage, b.damage])
	_assert(a.is_crit == b.is_crit, "same seed -> same crit roll")


# ─── Content registry ────────────────────────────────────────────────

func _test_content_loaded() -> void:
	print("\n[content registry]")
	_assert(ContentRegistry.get_hero("ember_knight") != null, "ember_knight loads")
	_assert(ContentRegistry.get_enemy("training_slime") != null, "training_slime loads")
	_assert(ContentRegistry.get_skill("basic_attack") != null, "basic_attack loads")
	_assert(ContentRegistry.get_skill("flame_slash") != null, "flame_slash loads")
	var ember: HeroData = ContentRegistry.get_hero("ember_knight")
	if ember != null:
		_assert(ember.skill_ids.size() >= 2, "ember_knight has >= 2 skill_ids")
		_assert(ember.element == Elements.FIRE, "ember_knight is FIRE")
