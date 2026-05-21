extends Node2D
## Phase 1 — Battle MVP scene controller.
##
## 1v1, simple round-based turn order (sort by SPD), direct damage resolution.
## Phase 2 upgrades:
##   - 5v5 party combat
##   - ATB turn order (replaces this round-based logic)
##   - Effect composition replaces direct Damage.compute() calls
##   - Status effects, cooldowns, ultimate gauge

const POPUP_SCENE := preload("res://scenes/battle/damage_popup.tscn")

@onready var _player_unit: Node2D = $PlayerUnit
@onready var _enemy_unit: Node2D = $EnemyUnit
@onready var _turn_label: Label = $UI/TurnLabel
@onready var _basic_btn: Button = $UI/Actions/BasicAttack
@onready var _flame_btn: Button = $UI/Actions/FlameSlash
@onready var _end_panel: ColorRect = $UI/EndPanel
@onready var _result_label: Label = $UI/EndPanel/EndVBox/ResultLabel
@onready var _popup_layer: Node2D = $PopupLayer

const TEST_HERO_ID := "ember_knight"
const TEST_ENEMY_ID := "training_slime"

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
		_fail_setup("missing hero: " + TEST_HERO_ID)
		return
	if _enemy == null:
		_fail_setup("missing enemy: " + TEST_ENEMY_ID)
		return

	_player_stats = _hero_to_stats(_player_hero)
	_enemy_stats = _enemy_to_stats(_enemy)
	_player_hp = int(_player_stats.hp)
	_enemy_hp = int(_enemy_stats.hp)

	_player_unit.bind(_player_hero.display_name, _player_hero.sprite_color, _player_hp)
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
	if s != null:
		return s.skill_name
	return "Attack"


func _hero_to_stats(h: HeroData) -> Dictionary:
	return {
		"hp": h.base_hp,
		"atk": h.base_atk,
		"def": h.base_def,
		"spd": h.base_spd,
		"crit_rate": h.base_crit_rate,
		"crit_dmg": h.base_crit_dmg,
		"acc": h.base_acc,
		"eva": h.base_eva,
		"luk": h.base_luk,
		"res": h.base_res,
		"element": h.element,
	}


func _enemy_to_stats(e: EnemyData) -> Dictionary:
	return {
		"hp": e.hp,
		"atk": e.atk,
		"def": e.def,
		"spd": e.spd,
		"crit_rate": e.crit_rate,
		"crit_dmg": e.crit_dmg,
		"acc": e.acc,
		"eva": e.eva,
		"luk": e.luk,
		"res": e.res,
		"element": e.element,
	}


func _begin_round() -> void:
	if _battle_over:
		return
	_round += 1
	_turn_label.text = "Round %d — your move" % _round
	_set_actions_enabled(_player_stats.spd >= _enemy_stats.spd)
	if _player_stats.spd < _enemy_stats.spd:
		# Enemy acts first
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


func _player_uses(skill_id: String) -> void:
	var skill: SkillData = ContentRegistry.get_skill(skill_id)
	if skill == null:
		push_error("[Battle] missing skill: " + skill_id)
		return
	_set_actions_enabled(false)

	var element := skill.element if skill.element >= 0 else int(_player_stats.element)
	var hit := Damage.is_hit(_player_stats, _enemy_stats, _rng)
	if not hit:
		_spawn_text_popup(_enemy_unit.global_position + Vector2(0, -180), "MISS", Color(0.7, 0.7, 0.7))
		print("[Battle] %s -> %s MISSED" % [_player_hero.display_name, _enemy.display_name])
	else:
		var result := Damage.compute(_player_stats, _enemy_stats, skill.power, element, _rng)
		_enemy_hp = max(0, _enemy_hp - int(result.damage))
		_enemy_unit.set_hp(_enemy_hp, int(_enemy_stats.hp))
		_spawn_popup(_enemy_unit.global_position + Vector2(0, -180), result.damage, result.is_crit, result.is_lucky)
		EventBus.damage_dealt.emit(_player_hero.id, _enemy.id, result.damage, result.is_crit)
		print("[Battle] %s -> %s : %d dmg (crit=%s lucky=%s elem=%.1fx)" % [
			_player_hero.display_name, _enemy.display_name,
			result.damage, result.is_crit, result.is_lucky, result.elemental,
		])

	await get_tree().create_timer(0.55).timeout

	if _enemy_hp <= 0:
		_end_battle(true)
		return

	# Enemy responds
	await _enemy_turn()
	if _battle_over:
		return
	_begin_round()


func _enemy_turn() -> void:
	_turn_label.text = "Round %d — enemy moves" % _round
	await get_tree().create_timer(0.35).timeout

	var hit := Damage.is_hit(_enemy_stats, _player_stats, _rng)
	if not hit:
		_spawn_text_popup(_player_unit.global_position + Vector2(0, -180), "MISS", Color(0.7, 0.7, 0.7))
		print("[Battle] %s -> %s MISSED" % [_enemy.display_name, _player_hero.display_name])
	else:
		var result := Damage.compute(_enemy_stats, _player_stats, _enemy.attack_power, int(_enemy_stats.element), _rng)
		_player_hp = max(0, _player_hp - int(result.damage))
		_player_unit.set_hp(_player_hp, int(_player_stats.hp))
		_spawn_popup(_player_unit.global_position + Vector2(0, -180), result.damage, result.is_crit, result.is_lucky)
		EventBus.damage_dealt.emit(_enemy.id, _player_hero.id, result.damage, result.is_crit)
		print("[Battle] %s -> %s : %d dmg" % [_enemy.display_name, _player_hero.display_name, result.damage])

	await get_tree().create_timer(0.55).timeout

	if _player_hp <= 0:
		_end_battle(false)


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


func _end_battle(victory: bool) -> void:
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


func _on_return_pressed() -> void:
	Game.change_scene("res://scenes/hub/hub.tscn")


func _fail_setup(reason: String) -> void:
	push_error("[Battle] setup failed: " + reason)
	_turn_label.text = "Battle setup failed: " + reason
	_set_actions_enabled(false)
