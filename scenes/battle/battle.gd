extends Node2D
## Phase 2c — ATB turn order.
##
## Round-based logic is gone. Each unit's ATB gauge fills proportional to
## its (effective) SPD. The unit whose gauge fills first acts. After acting,
## its ATB drops by the skill's atb_cost.
##
## SPD modifiers (from Brace if it ever boosted SPD, or future status types)
## now meaningfully change turn frequency over the course of a battle.

const POPUP_SCENE := preload("res://scenes/battle/damage_popup.tscn")
const SLASH_SCENE := preload("res://scenes/battle/slash_effect.tscn")
const MAX_SKILL_SLOTS := 4

@onready var _player_unit: Node2D = $PlayerUnit
@onready var _enemy_unit: Node2D = $EnemyUnit
@onready var _turn_label: Label = $UI/TurnPanel/TurnLabel
@onready var _turn_order_bar: HBoxContainer = $UI/TurnOrderBar
@onready var _end_panel: ColorRect = $UI/EndPanel
@onready var _result_label: Label = $UI/EndPanel/EndVBox/ResultLabel
@onready var _popup_layer: Node2D = $PopupLayer
@onready var _camera: Camera2D = $Camera
@onready var _actions_hbox: HBoxContainer = $UI/ActionPanel/Actions

const TEST_HERO_ID := "ember_knight"
const TEST_ENEMY_ID := "training_slime"

const LUNGE_DISTANCE := 42.0
const LUNGE_OUT := 0.12
const LUNGE_BACK := 0.16

const DEFAULT_ATB_COST := 100.0

signal _player_action_done

var _rng: SeededRNG
var _player_stats: Dictionary
var _enemy_stats: Dictionary
var _player_hp: int
var _enemy_hp: int
var _player_hero: HeroData
var _enemy: EnemyData
var _battle_over: bool = false
var _battle_id: String = ""
var _turn_counter: int = 0

var _atb_player: float = 0.0
var _atb_enemy: float = 0.0

var _skill_buttons: Array[Button] = []


func _ready() -> void:
	Game.transition_state(Game.State.BATTLE)
	_battle_id = "%d" % Time.get_ticks_msec()
	_rng = SeededRNG.new(int(Time.get_unix_time_from_system()))

	_player_hero = ContentRegistry.get_hero(TEST_HERO_ID)
	_enemy = ContentRegistry.get_enemy(TEST_ENEMY_ID)
	if _player_hero == null:
		_fail_setup("missing hero: " + TEST_HERO_ID); return
	if _enemy == null:
		_fail_setup("missing enemy: " + TEST_ENEMY_ID); return

	_player_stats = _hero_to_stats(_player_hero)
	_enemy_stats = _enemy_to_stats(_enemy)
	_player_hp = int(_player_stats.hp)
	_enemy_hp = int(_enemy_stats.hp)

	_player_unit.bind(
		_player_hero.display_name,
		_player_hero.sprite_color,
		_player_hp,
		_player_hero.idle_frames,
		_player_hero.sprite_scale,
		_player_hero.sprite_y_offset,
	)
	_enemy_unit.bind(_enemy.display_name, _enemy.sprite_color, _enemy_hp)

	_setup_skill_buttons()
	_turn_order_bar.register_unit(_player_hero.id, _player_hero.sprite_color, _player_hero.display_name)
	_turn_order_bar.register_unit(_enemy.id, _enemy.sprite_color, _enemy.display_name)
	_refresh_turn_order_bar()

	_end_panel.hide()
	EventBus.combat_started.emit(_battle_id)
	print("[Battle] starting — %s vs %s (seed=%d)" % [_player_hero.display_name, _enemy.display_name, _rng.rng.seed])
	_next_turn()


func _setup_skill_buttons() -> void:
	_skill_buttons.clear()
	for i in MAX_SKILL_SLOTS:
		var btn: Button = _actions_hbox.get_node("SkillBtn%d" % i)
		_skill_buttons.append(btn)
		var idx := i
		btn.pressed.connect(func(): _on_skill_pressed(idx))

	for i in MAX_SKILL_SLOTS:
		var btn: Button = _skill_buttons[i]
		if i < _player_hero.skill_ids.size():
			var s: SkillData = ContentRegistry.get_skill(_player_hero.skill_ids[i])
			btn.text = s.skill_name if s != null else "?"
			btn.tooltip_text = s.description if s != null else ""
			btn.visible = true
		else:
			btn.visible = false


func _hero_to_stats(h: HeroData) -> Dictionary:
	return {
		"hp": h.base_hp, "atk": h.base_atk, "def": h.base_def, "spd": h.base_spd,
		"crit_rate": h.base_crit_rate, "crit_dmg": h.base_crit_dmg,
		"acc": h.base_acc, "eva": h.base_eva, "luk": h.base_luk, "res": h.base_res,
		"element": h.element,
	}


func _enemy_to_stats(e: EnemyData) -> Dictionary:
	return {
		"hp": e.hp, "atk": e.atk, "def": e.def, "spd": e.spd,
		"crit_rate": e.crit_rate, "crit_dmg": e.crit_dmg,
		"acc": e.acc, "eva": e.eva, "luk": e.luk, "res": e.res,
		"element": e.element,
	}


func _effective_stats(base: Dictionary, sm: StatusManager) -> Dictionary:
	var result := base.duplicate(true)
	result["atk"] = int(float(base["atk"]) * sm.get_stat_multiplier("atk"))
	result["def"] = int(float(base["def"]) * sm.get_stat_multiplier("def"))
	result["spd"] = int(float(base["spd"]) * sm.get_stat_multiplier("spd"))
	result["acc"] = float(base["acc"]) * sm.get_stat_multiplier("acc")
	result["eva"] = float(base["eva"]) * sm.get_stat_multiplier("eva")
	result["crit_rate"] = float(base["crit_rate"]) * sm.get_stat_multiplier("crit_rate")
	return result


# ─── ATB scheduler glue ──────────────────────────────────────────────

func _atb_states() -> Array:
	# Fresh effective SPDs each time — so SPD buffs/debuffs change scheduling
	# the moment they're applied/expired.
	var p_eff := _effective_stats(_player_stats, _player_unit.statuses)
	var e_eff := _effective_stats(_enemy_stats, _enemy_unit.statuses)
	return [
		{"id": _player_hero.id, "atb": _atb_player, "spd": float(p_eff.spd), "alive": _player_hp > 0},
		{"id": _enemy.id, "atb": _atb_enemy, "spd": float(e_eff.spd), "alive": _enemy_hp > 0},
	]


func _commit_atb(new_states: Array) -> void:
	for s in new_states:
		if s.id == _player_hero.id:
			_atb_player = float(s.atb)
		elif s.id == _enemy.id:
			_atb_enemy = float(s.atb)


func _refresh_turn_order_bar() -> void:
	var sequence: Array = ATBScheduler.predict_sequence(_atb_states(), 5)
	_turn_order_bar.set_sequence(sequence)


# ─── Main loop ───────────────────────────────────────────────────────

func _next_turn() -> void:
	if _battle_over: return

	var step: Dictionary = ATBScheduler.next_actor(_atb_states())
	if step.is_empty():
		return  # nothing alive — shouldn't happen, but safe
	_commit_atb(step.new_states)
	_refresh_turn_order_bar()

	_turn_counter += 1
	var actor_id: String = step.actor_id

	if actor_id == _player_hero.id:
		await _do_player_turn()
	else:
		await _do_enemy_turn()

	if _battle_over: return
	_next_turn()


# ─── Player turn ─────────────────────────────────────────────────────

func _do_player_turn() -> void:
	if _player_unit.statuses.is_stunned():
		_turn_label.text = "Stunned"
		_spawn_text_popup(_player_unit.global_position + Vector2(0, -260), "STUNNED", Color(0.95, 0.85, 0.3))
		await get_tree().create_timer(0.7).timeout
		ATBScheduler.deduct(_atb_states(), _player_hero.id, DEFAULT_ATB_COST)
		_atb_player = max(0.0, _atb_player - DEFAULT_ATB_COST)
	else:
		_turn_label.text = "Your move"
		_set_actions_enabled(true)
		await _player_action_done

	await _tick_unit_statuses(_player_unit, _player_stats, true)
	_check_end_battle()


func _set_actions_enabled(enabled: bool) -> void:
	for btn in _skill_buttons:
		if btn.visible:
			btn.disabled = not enabled


func _on_skill_pressed(idx: int) -> void:
	if _battle_over: return
	if idx >= _player_hero.skill_ids.size(): return
	_set_actions_enabled(false)
	var skill_id: String = _player_hero.skill_ids[idx]
	var skill: SkillData = ContentRegistry.get_skill(skill_id)
	if skill == null:
		push_error("[Battle] missing skill: " + skill_id)
		_set_actions_enabled(true)
		return
	await _player_uses(skill_id)
	# Deduct the skill's ATB cost (default 100 if not set)
	var cost: float = float(skill.atb_cost) if skill.atb_cost > 0 else DEFAULT_ATB_COST
	_atb_player = max(0.0, _atb_player - cost)
	_refresh_turn_order_bar()
	_player_action_done.emit()


func _player_uses(skill_id: String) -> void:
	var skill: SkillData = ContentRegistry.get_skill(skill_id)
	if skill == null: return

	var is_self: bool = skill.target_type == 4
	var target_stats: Dictionary
	var target_id: String
	var target_unit: Node2D
	if is_self:
		target_stats = _player_stats
		target_id = _player_hero.id
		target_unit = _player_unit
	else:
		target_stats = _enemy_stats
		target_id = _enemy.id
		target_unit = _enemy_unit

	if not is_self:
		_lunge(_player_unit, _enemy_unit.global_position)
		await get_tree().create_timer(LUNGE_OUT).timeout
	else:
		var puff := create_tween()
		puff.tween_property(_player_unit, "scale", Vector2(1.06, 1.06), 0.10)
		puff.tween_property(_player_unit, "scale", Vector2(1.0, 1.0), 0.18)
		await get_tree().create_timer(0.15).timeout

	var attacker_eff := _effective_stats(_player_stats, _player_unit.statuses)
	var target_eff := _effective_stats(target_stats, target_unit.statuses)

	await _resolve_skill(skill, attacker_eff, target_eff, _player_hero.id, target_id, target_unit)

	if not is_self:
		await get_tree().create_timer(LUNGE_BACK + 0.30).timeout
	else:
		await get_tree().create_timer(0.45).timeout


# ─── Enemy turn ──────────────────────────────────────────────────────

func _do_enemy_turn() -> void:
	_turn_label.text = "%s moves" % _enemy.display_name
	await get_tree().create_timer(0.35).timeout

	if _enemy_unit.statuses.is_stunned():
		_spawn_text_popup(_enemy_unit.global_position + Vector2(0, -260), "STUNNED", Color(0.95, 0.85, 0.3))
		await get_tree().create_timer(0.7).timeout
	else:
		var enemy_skill := _make_enemy_skill()
		_lunge(_enemy_unit, _player_unit.global_position)
		await get_tree().create_timer(LUNGE_OUT).timeout

		var attacker_eff := _effective_stats(_enemy_stats, _enemy_unit.statuses)
		var target_eff := _effective_stats(_player_stats, _player_unit.statuses)

		await _resolve_skill(enemy_skill, attacker_eff, target_eff, _enemy.id, _player_hero.id, _player_unit)
		await get_tree().create_timer(LUNGE_BACK + 0.30).timeout

	_atb_enemy = max(0.0, _atb_enemy - DEFAULT_ATB_COST)
	_refresh_turn_order_bar()

	await _tick_unit_statuses(_enemy_unit, _enemy_stats, false)
	_check_end_battle()


func _make_enemy_skill() -> SkillData:
	var skill := SkillData.new()
	skill.id = "enemy_basic"
	skill.skill_name = "Slam"
	skill.element = int(_enemy_stats.element)
	skill.target_type = 0
	skill.atb_cost = 100
	var dmg := EffectDamage.new()
	dmg.power_mult = _enemy.attack_power
	dmg.hits = 1
	skill.effects = [dmg]
	return skill


# ─── Effect resolution ───────────────────────────────────────────────

func _resolve_skill(skill: SkillData, attacker_stats: Dictionary, target_stats: Dictionary, attacker_id: String, target_id: String, target_unit: Node2D) -> void:
	for effect in skill.effects:
		var ctx := EffectContext.new(attacker_stats, target_stats, attacker_id, target_id, skill, _rng)
		var result: Dictionary = effect.apply(ctx)
		_apply_result(result, attacker_id, target_id, target_unit)
		if result.get("kind") == "miss":
			break


func _apply_result(result: Dictionary, attacker_id: String, target_id: String, target_unit: Node2D) -> void:
	match result.get("kind", "none"):
		"damage":
			var amount: int = int(result.damage)
			if target_id == _enemy.id:
				_enemy_hp = max(0, _enemy_hp - amount)
				target_unit.set_hp(_enemy_hp, int(_enemy_stats.hp))
			else:
				_player_hp = max(0, _player_hp - amount)
				target_unit.set_hp(_player_hp, int(_player_stats.hp))
			_spawn_popup(target_unit.global_position + Vector2(0, -200), amount, result.is_crit, result.is_lucky)
			var flipped: bool = attacker_id != _player_hero.id
			var slash_x: int = 20 if flipped else -20
			_spawn_slash(target_unit.global_position + Vector2(slash_x, -110), flipped)
			if result.is_crit:
				_shake_camera(9.0, 0.18)
			else:
				_shake_camera(3.0, 0.10)
			EventBus.damage_dealt.emit(attacker_id, target_id, amount, result.is_crit)
			print("[Battle] %s -> %s : %d dmg (crit=%s lucky=%s elem=%.1fx)" % [
				attacker_id, target_id, amount, result.is_crit, result.is_lucky, result.elemental_mult,
			])
		"miss":
			_spawn_text_popup(target_unit.global_position + Vector2(0, -200), "MISS", Color(0.7, 0.7, 0.7))
			print("[Battle] %s -> %s MISSED" % [attacker_id, target_id])
		"status":
			var data: StatusEffectData = ContentRegistry.get_status(result.status_id)
			if data == null:
				push_error("[Battle] missing status: " + str(result.status_id)); return
			target_unit.add_status(result.status_id, result.duration, result.power, data)
			_spawn_text_popup(target_unit.global_position + Vector2(0, -260), data.display_name.to_upper(), data.icon_color)
			EventBus.status_applied.emit(target_id, result.status_id)
			print("[Battle] %s applied %s to %s (%d turns)" % [attacker_id, result.status_id, target_id, result.duration])
		"status_resisted":
			_spawn_text_popup(target_unit.global_position + Vector2(0, -260), "RESIST", Color(0.6, 0.8, 1.0))
			print("[Battle] %s resisted %s" % [target_id, result.status_id])
		"heal":
			var amount: int = int(result.amount)
			if target_id == _enemy.id:
				_enemy_hp = min(int(_enemy_stats.hp), _enemy_hp + amount)
				target_unit.set_hp(_enemy_hp, int(_enemy_stats.hp))
			else:
				_player_hp = min(int(_player_stats.hp), _player_hp + amount)
				target_unit.set_hp(_player_hp, int(_player_stats.hp))
			_spawn_text_popup(target_unit.global_position + Vector2(0, -200), "+%d" % amount, Color(0.4, 0.85, 0.4))
		"none":
			pass


# ─── Status ticks ────────────────────────────────────────────────────

func _tick_unit_statuses(unit: Node2D, stats: Dictionary, is_player: bool) -> void:
	var results: Array = unit.statuses.tick_end_of_turn(stats)
	for result in results:
		match result.get("kind"):
			"tick_damage":
				var amount: int = int(result.amount)
				if is_player:
					_player_hp = max(0, _player_hp - amount)
					unit.set_hp(_player_hp, int(_player_stats.hp))
				else:
					_enemy_hp = max(0, _enemy_hp - amount)
					unit.set_hp(_enemy_hp, int(_enemy_stats.hp))
				_spawn_dot_popup(unit.global_position + Vector2(0, -200), amount, result.status_id)
				print("[Battle] %s tick %s -> %d" % [unit.name, result.status_id, amount])
				await get_tree().create_timer(0.20).timeout
			"status_expired":
				print("[Battle] %s expired on %s" % [result.status_id, unit.name])
	unit.refresh_status_durations()
	_refresh_turn_order_bar()  # in case the status change affected SPD


func _spawn_dot_popup(at: Vector2, amount: int, status_id: String) -> void:
	var data: StatusEffectData = ContentRegistry.get_status(status_id)
	var color: Color = data.icon_color if data != null else Color(0.9, 0.55, 0.3)
	var popup := POPUP_SCENE.instantiate()
	_popup_layer.add_child(popup)
	popup.global_position = at
	popup.show_text(str(amount), color, 22)


# ─── End-of-battle ───────────────────────────────────────────────────

func _check_end_battle() -> bool:
	if _enemy_hp <= 0:
		_end_battle(true); return true
	if _player_hp <= 0:
		_end_battle(false); return true
	return false


func _end_battle(victory: bool) -> void:
	if _battle_over: return
	_battle_over = true
	_set_actions_enabled(false)
	_result_label.text = "VICTORY" if victory else "DEFEAT"
	_result_label.add_theme_color_override(
		"font_color",
		Color(0.97, 0.78, 0.31) if victory else Color(0.93, 0.35, 0.4),
	)
	_end_panel.show()
	EventBus.combat_ended.emit(_battle_id, victory)
	print("[Battle] ended — ", "VICTORY" if victory else "DEFEAT")


# ─── VFX helpers ─────────────────────────────────────────────────────

func _lunge(unit: Node2D, toward: Vector2) -> void:
	var origin := unit.position
	var dir := (toward - unit.global_position).normalized()
	var target := origin + dir * LUNGE_DISTANCE
	var tween := create_tween()
	tween.tween_property(unit, "position", target, LUNGE_OUT).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(unit, "position", origin, LUNGE_BACK).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


func _spawn_slash(at: Vector2, flipped: bool) -> void:
	var effect := SLASH_SCENE.instantiate()
	_popup_layer.add_child(effect)
	effect.global_position = at
	effect.set_flipped(flipped)


func _shake_camera(amount: float, duration: float) -> void:
	var steps := 6
	var step_dur := duration / steps
	var tween := create_tween()
	for i in steps:
		var jitter := Vector2(_rng.range_float(-amount, amount), _rng.range_float(-amount, amount))
		tween.tween_property(_camera, "offset", jitter, step_dur)
	tween.tween_property(_camera, "offset", Vector2.ZERO, step_dur)


func _spawn_popup(at: Vector2, amount: int, is_crit: bool, is_lucky: bool) -> void:
	var popup := POPUP_SCENE.instantiate()
	_popup_layer.add_child(popup)
	popup.global_position = at
	popup.show_damage(amount, is_crit, is_lucky)


func _spawn_text_popup(at: Vector2, text: String, color: Color) -> void:
	var popup := POPUP_SCENE.instantiate()
	_popup_layer.add_child(popup)
	popup.global_position = at
	popup.show_text(text, color, 24)


func _on_return_pressed() -> void:
	Game.change_scene("res://scenes/hub/hub.tscn")


func _fail_setup(reason: String) -> void:
	push_error("[Battle] setup failed: " + reason)
	_turn_label.text = "Battle setup failed: " + reason
	_set_actions_enabled(false)
