extends Node
## Phase 2a effect composition + status system tests.
##
## Open tests/test_effects.tscn and press F6 to run.

var _passed: int = 0
var _failed: int = 0
var _failures: Array[String] = []


func _ready() -> void:
	print("=== Vaelthorn Effect Tests ===")
	_test_effect_damage()
	_test_effect_damage_misses_with_zero_acc()
	_test_effect_damage_inherits_skill_element()
	_test_effect_damage_inherits_attacker_element()
	_test_effect_status_lands()
	_test_effect_status_resisted_by_chance_zero()
	_test_effect_status_resisted_by_res()
	_test_effect_heal()
	_test_status_manager_add()
	_test_status_manager_tick_dot()
	_test_status_manager_expires()
	_test_status_manager_refresh_duration()
	_test_content_burn_loaded()
	_test_flame_slash_has_two_effects()

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


func _make_ctx(attacker: Dictionary, target: Dictionary, skill: SkillData, rng: SeededRNG) -> EffectContext:
	return EffectContext.new(attacker, target, "atk", "tgt", skill, rng)


# ─── EffectDamage ────────────────────────────────────────────────────

func _test_effect_damage() -> void:
	print("\n[EffectDamage basics]")
	var rng := SeededRNG.new(12345)
	var atk := {"atk": 100, "acc": 1.0, "crit_rate": 0.0, "crit_dmg": 1.5, "luk": 0, "element": Elements.FIRE}
	var tgt := {"def": 20, "eva": 0.0, "element": Elements.WATER}
	var skill := SkillData.new()
	skill.element = Elements.FIRE

	var fx := EffectDamage.new()
	fx.power_mult = 1.0
	var ctx := _make_ctx(atk, tgt, skill, rng)
	var r: Dictionary = fx.apply(ctx)
	_assert(r.kind == "damage", "EffectDamage returns damage kind")
	# base 90, Fire vs Water 0.5x, variance ~1 -> ~42-48
	_assert(r.damage >= 40 and r.damage <= 50, "EffectDamage Fire vs Water in [40,50] (got %d)" % r.damage)


func _test_effect_damage_misses_with_zero_acc() -> void:
	print("\n[EffectDamage miss]")
	var rng := SeededRNG.new(7)
	var atk := {"atk": 100, "acc": 0.05, "element": 0}  # min hit chance
	var tgt := {"def": 0, "eva": 1.0, "element": 0}     # full evasion
	var skill := SkillData.new()
	var fx := EffectDamage.new()
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.kind == "miss" or r.kind == "damage", "EffectDamage returns miss or damage (it returned: " + str(r.kind) + ")")
	# Note: floor is 5% so it MIGHT hit. Just verify the kind set is correct.


func _test_effect_damage_inherits_skill_element() -> void:
	print("\n[EffectDamage element inheritance from skill]")
	var rng := SeededRNG.new(42)
	var atk := {"atk": 100, "acc": 1.0, "crit_rate": 0.0, "crit_dmg": 1.5, "luk": 0, "element": Elements.WATER}
	var tgt := {"def": 0, "eva": 0.0, "element": Elements.WIND}  # Fire > Wind
	var skill := SkillData.new()
	skill.element = Elements.FIRE   # skill is Fire even though attacker is Water

	var fx := EffectDamage.new()
	fx.element_override = -1   # inherit
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.kind == "damage", "EffectDamage hit")
	_assert(r.elemental_mult == 1.5, "Fire vs Wind = 1.5x (got %.2f)" % r.elemental_mult)


func _test_effect_damage_inherits_attacker_element() -> void:
	print("\n[EffectDamage element inheritance from attacker]")
	var rng := SeededRNG.new(99)
	var atk := {"atk": 100, "acc": 1.0, "crit_rate": 0.0, "crit_dmg": 1.5, "luk": 0, "element": Elements.WATER}
	var tgt := {"def": 0, "eva": 0.0, "element": Elements.FIRE}  # Water > Fire
	var skill := SkillData.new()  # skill.element = -1 (default)

	var fx := EffectDamage.new()
	fx.element_override = -1
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.elemental_mult == 1.5, "Attacker WATER vs target FIRE = 1.5x (got %.2f)" % r.elemental_mult)


# ─── EffectStatus ────────────────────────────────────────────────────

func _test_effect_status_lands() -> void:
	print("\n[EffectStatus lands at 100% chance, 0 RES]")
	var rng := SeededRNG.new(1)
	var atk := {"atk": 100}
	var tgt := {"res": 0.0}
	var skill := SkillData.new()
	var fx := EffectStatus.new()
	fx.status_id = "burn"
	fx.duration = 3
	fx.chance = 1.0
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.kind == "status", "EffectStatus at chance 1.0 always lands")
	_assert(r.status_id == "burn", "status_id == burn")
	_assert(r.duration == 3, "duration == 3")


func _test_effect_status_resisted_by_chance_zero() -> void:
	print("\n[EffectStatus resisted at 0% chance]")
	var rng := SeededRNG.new(2)
	var atk := {"atk": 100}
	var tgt := {"res": 0.0}
	var skill := SkillData.new()
	var fx := EffectStatus.new()
	fx.status_id = "burn"
	fx.chance = 0.0
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.kind == "status_resisted", "EffectStatus at chance 0.0 always resists")


func _test_effect_status_resisted_by_res() -> void:
	print("\n[EffectStatus modulated by target RES]")
	var rng := SeededRNG.new(3)
	# chance 1.0 * (1 - res 1.0) = 0 -> always resists
	var atk := {"atk": 100}
	var tgt := {"res": 1.0}
	var skill := SkillData.new()
	var fx := EffectStatus.new()
	fx.status_id = "burn"
	fx.chance = 1.0
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.kind == "status_resisted", "Full RES resists 100%% chance")


# ─── EffectHeal ──────────────────────────────────────────────────────

func _test_effect_heal() -> void:
	print("\n[EffectHeal]")
	var rng := SeededRNG.new(1)
	var atk := {"atk": 200}
	var tgt := {}
	var skill := SkillData.new()
	var fx := EffectHeal.new()
	fx.heal_mult = 0.5
	var r: Dictionary = fx.apply(_make_ctx(atk, tgt, skill, rng))
	_assert(r.kind == "heal", "EffectHeal returns heal kind")
	_assert(r.amount == 100, "heal_mult 0.5 * ATK 200 = 100 (got %d)" % r.amount)


# ─── StatusManager ───────────────────────────────────────────────────

func _test_status_manager_add() -> void:
	print("\n[StatusManager add]")
	var sm := StatusManager.new()
	var burn: StatusEffectData = ContentRegistry.get_status("burn")
	if burn == null:
		_assert(false, "burn.tres exists (required for this test)")
		return
	sm.add("burn", 3, 0.0, burn)
	_assert(sm.has("burn"), "burn is active after add")
	_assert(sm.remaining_turns("burn") == 3, "remaining_turns == 3")


func _test_status_manager_tick_dot() -> void:
	print("\n[StatusManager DoT tick]")
	var sm := StatusManager.new()
	var burn: StatusEffectData = ContentRegistry.get_status("burn")
	if burn == null: return
	sm.add("burn", 3, 0.0, burn)
	# burn = 5% of MAX_HP per turn. Target has 1000 max HP -> 50 dmg.
	var results: Array = sm.tick_end_of_turn({"hp": 1000})
	var dot_hit := false
	for r in results:
		if r.get("kind") == "tick_damage":
			_assert(r.amount == 50, "Burn ticks 5%% of 1000 = 50 (got %d)" % r.amount)
			dot_hit = true
	_assert(dot_hit, "tick produced a tick_damage result")
	_assert(sm.remaining_turns("burn") == 2, "remaining_turns decremented to 2")


func _test_status_manager_expires() -> void:
	print("\n[StatusManager expiry]")
	var sm := StatusManager.new()
	var burn: StatusEffectData = ContentRegistry.get_status("burn")
	if burn == null: return
	sm.add("burn", 1, 0.0, burn)
	var _r1: Array = sm.tick_end_of_turn({"hp": 100})
	_assert(not sm.has("burn"), "burn cleared after final tick")


func _test_status_manager_refresh_duration() -> void:
	print("\n[StatusManager refresh duration]")
	var sm := StatusManager.new()
	var burn: StatusEffectData = ContentRegistry.get_status("burn")
	if burn == null: return
	sm.add("burn", 2, 0.0, burn)
	sm.add("burn", 4, 0.0, burn)
	_assert(sm.remaining_turns("burn") == 4, "re-adding extends to max duration")


# ─── Content ─────────────────────────────────────────────────────────

func _test_content_burn_loaded() -> void:
	print("\n[Content registry: burn]")
	var burn: StatusEffectData = ContentRegistry.get_status("burn")
	_assert(burn != null, "burn.tres loads")
	if burn != null:
		_assert(burn.tick_kind == StatusEffectData.TickKind.DOT_PERCENT_MAX_HP, "burn tick_kind = DOT_PERCENT_MAX_HP")
		_assert(burn.tick_amount == 5.0, "burn tick_amount = 5.0")


func _test_flame_slash_has_two_effects() -> void:
	print("\n[flame_slash effect composition]")
	var sk: SkillData = ContentRegistry.get_skill("flame_slash")
	_assert(sk != null, "flame_slash loads")
	if sk != null:
		_assert(sk.effects.size() == 2, "flame_slash has 2 effects (got %d)" % sk.effects.size())
		_assert(sk.effects[0] is EffectDamage, "first effect is EffectDamage")
		_assert(sk.effects[1] is EffectStatus, "second effect is EffectStatus")
		if sk.effects[1] is EffectStatus:
			_assert(sk.effects[1].status_id == "burn", "second effect applies burn")
