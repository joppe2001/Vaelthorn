extends Node2D
## Phase 2a — Effect Composition battle controller.
##
## Skills no longer pass scalar power/element to a damage call; they iterate
## their `effects: Array[Effect]`, call apply(ctx) on each, and the battle
## scene processes the resulting dictionaries.
##
## End-of-turn ticks (DoT, buff decay) live on each unit's StatusManager.
## Phase 2b adds: 5v5, ATB turn order, more statuses, ultimate gauge.

const POPUP_SCENE := preload("res://scenes/battle/damage_popup.tscn")
const SLASH_SCENE := preload("res://scenes/battle/slash_effect.tscn")

@onready var _player_unit: Node2D = $PlayerUnit
@onready var _enemy_unit: Node2D = $EnemyUnit
@onready var _turn_label: Label = $UI/TurnPanel/TurnLabel
@onready var _basic_btn: Button = $UI/ActionPanel/Actions/BasicAttack
@onready var _flame_btn: Button = $UI/ActionPanel/Actions/FlameSlash
@onready var _end_panel: ColorRect = $UI/EndPanel
@onready var _result_label: Label = $UI/EndPanel/EndVBox/ResultLabel
@onready var _popup_layer: Node2D = $PopupLayer
@onready var _camera: Camera2D = $Camera

const TEST_HERO_ID := "ember_knight"
const TEST_ENEMY_ID := "training_slime"

const LUNGE_DISTANCE := 42.0
const LUNGE_OUT := 0.12
const LUNGE_BACK := 0.16

var _rng: SeededRNG
var _player_stats: Dictionary
var _enemy_stats: Dictionary
var _player_hp: int
var _enemy_hp: int
var _player_hero: HeroData
var _enemy: EnemyData
var _battle_over: bool = false
var _round: int = 0
var _battle_id: String = ""


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

	_basic_btn.text = _label_for_skill(_player_hero.skill_ids[0] if _player_hero.skill_ids.size() > 0 else "")
	if _player_hero.skill_ids.size() > 1:
		_flame_btn.text = _label_for_skill(_player_hero.skill_ids[1])
		_flame_btn.visible = true
	else:
		_flame_btn.visible = false

	_end_panel.hide()
	EventBus.combat_started.emit(_battle_id)
	print("[Battle] starting — %s vs %s (seed=%d)" % [_player_hero.display_name, _enemy.display_name, _rng.rng.seed])
	_begin_round()


func _label_for_skill(skill_id: String) -> String:
	var s := ContentRegistry.get_skill(skill_id)
	return s.skill_name if s != null else "Attack"


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


func _begin_round() -> void:
	if _battle_over: return
	_round += 1
	_turn_label.text = "Round %d — your move" % _round
	_set_actions_enabled(_player_stats.spd >= _enemy_stats.spd)
	if _player_stats.spd < _enemy_stats.spd:
		_turn_label.text = "Round %d — enemy moves" % _round
		await _enemy_turn()


func _set_actions_enabled(enabled: bool) -> void:
	_basic_btn.disabled = not enabled
	_flame_btn.disabled = not enabled


func _on_basic_attack_pressed() -> void:
	if _battle_over: return
	if _player_hero.skill_ids.size() == 0: return
	await _player_uses(_player_hero.skill_ids[0])


func _on_flame_slash_pressed() -> void:
	if _battle_over: return
	if _player_hero.skill_ids.size() < 2: return
	await _player_uses(_player_hero.skill_ids[1])


# ─── Turns ───────────────────────────────────────────────────────────

func _player_uses(skill_id: String) -> void:
	var skill: SkillData = ContentRegistry.get_skill(skill_id)
	if skill == null:
		push_error("[Battle] missing skill: " + skill_id); return
	_set_actions_enabled(false)

	# If stunned, skip the turn (architecture-ready for Phase 2b stun.tres).
	if _player_unit.statuses.is_stunned():
		_spawn_text_popup(_player_unit.global_position + Vector2(0, -240), "STUNNED", Color(0.9, 0.9, 0.3))
		await get_tree().create_timer(0.6).timeout
	else:
		_lunge(_player_unit, _enemy_unit.global_position)
		await get_tree().create_timer(LUNGE_OUT).timeout
		await _resolve_skill(skill, _player_stats, _enemy_stats, _player_hero.id, _enemy.id, _enemy_unit)
		await get_tree().create_timer(LUNGE_BACK + 0.30).timeout

	await _tick_unit_statuses(_player_unit, _player_stats, true)
	if _check_end_battle(): return

	await _enemy_turn()
	if _battle_over: return
	_begin_round()


func _enemy_turn() -> void:
	_turn_label.text = "Round %d — enemy moves" % _round
	await get_tree().create_timer(0.35).timeout

	if _enemy_unit.statuses.is_stunned():
		_spawn_text_popup(_enemy_unit.global_position + Vector2(0, -240), "STUNNED", Color(0.9, 0.9, 0.3))
		await get_tree().create_timer(0.6).timeout
	else:
		var enemy_skill := _make_enemy_skill()
		_lunge(_enemy_unit, _player_unit.global_position)
		await get_tree().create_timer(LUNGE_OUT).timeout
		await _resolve_skill(enemy_skill, _enemy_stats, _player_stats, _enemy.id, _player_hero.id, _player_unit)
		await get_tree().create_timer(LUNGE_BACK + 0.30).timeout

	await _tick_unit_statuses(_enemy_unit, _enemy_stats, false)
	_check_end_battle()


func _make_enemy_skill() -> SkillData:
	# Phase 2a: enemies don't yet have authored .tres skills. Construct a
	# synthetic basic-attack skill so the effect pipeline is uniform.
	var skill := SkillData.new()
	skill.id = "enemy_basic"
	skill.skill_name = "Slam"
	skill.element = int(_enemy_stats.element)
	skill.target_type = 0
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
				push_error("[Battle] missing status: " + str(result.status_id))
				return
			target_unit.add_status(result.status_id, result.duration, result.power, data)
			_spawn_text_popup(target_unit.global_position + Vector2(0, -260), data.display_name.to_upper(), data.icon_color)
			EventBus.status_applied.emit(target_id, result.status_id)
			print("[Battle] %s applied %s to %s (%d turns)" % [attacker_id, result.status_id, target_id, result.duration])
		"status_resisted":
			_spawn_text_popup(target_unit.global_position + Vector2(0, -260), "RESIST", Color(0.6, 0.8, 1.0))
			print("[Battle] %s resisted %s" % [target_id, result.status_id])
		"heal":
			var amount: int = int(result.amount)
			# Phase 2a: heals not used yet. When they are, target_id matches caster.
			# Apply to whoever target_unit is.
			if target_id == _enemy.id:
				_enemy_hp = min(int(_enemy_stats.hp), _enemy_hp + amount)
				target_unit.set_hp(_enemy_hp, int(_enemy_stats.hp))
			else:
				_player_hp = min(int(_player_stats.hp), _player_hp + amount)
				target_unit.set_hp(_player_hp, int(_player_stats.hp))
			_spawn_text_popup(target_unit.global_position + Vector2(0, -200), "+%d" % amount, Color(0.4, 0.85, 0.4))
		"none":
			pass


# ─── Status ticks (end of turn) ──────────────────────────────────────

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
