extends Node2D
## Phase 2e — 3v3 party combat.
##
## Mirrors Phase 2d's enemy-side array work onto the hero side. Both sides
## are now arrays. The ATB scheduler handles all 6 units uniformly. When
## it's a hero's turn, the action panel repopulates with THAT hero's
## skill_ids, the active hero gets a cyan underline marker, and the player
## picks a skill. Enemy AI picks a random alive hero to attack.
##
## Win = all 3 enemies dead. Lose = all 3 heroes dead.

const POPUP_SCENE := preload("res://scenes/battle/damage_popup.tscn")
const SLASH_SCENE := preload("res://scenes/battle/slash_effect.tscn")
const HEAL_VFX_SCENE := preload("res://scenes/battle/heal_effect.tscn")
const BUFF_VFX_SCENE := preload("res://scenes/battle/buff_effect.tscn")
const DEBUFF_VFX_SCENE := preload("res://scenes/battle/debuff_effect.tscn")
const ULT_CUTIN_SCENE := preload("res://scenes/battle/ult_cutin.tscn")
const ELEMENT_BURST_SCENE := preload("res://scenes/battle/element_burst.tscn")
const MAX_SKILL_SLOTS := 4

# Fallback if Game.selected_party_ids is empty/malformed. Party Builder
# (Phase 3b) writes the real selection; this just keeps the battle scene
# launchable from the editor too.
const FALLBACK_PARTY_HERO_IDS := ["ember_knight", "crimson_lancer", "cinder_squire"]
const HERO_COUNT := 3
const ENEMY_COUNT := 3
const TEST_ENEMY_ID := "training_slime"

# Distance the attacker stops short of the target. Big enough that the
# attacker and target sprites don't overlap, small enough that the slash
# arc + impact reads as a proper engagement.
const APPROACH_GAP := 110.0
# Dash duration scales with distance so near and far attacks feel the
# same visual speed instead of teleporting. Clamped so short hops still
# take a beat and cross-screen dashes don't drag.
const DASH_SPEED := 2200.0
const DASH_DUR_MIN := 0.18
const DASH_DUR_MAX := 0.40
# Attack sequence beats: dash forward -> halt -> attack -> halt -> dash
# back. The two halts sell the engagement, the body anim plays during
# the attack window.
const IMPACT_PRE_PAUSE := 0.10
const IMPACT_POST_PAUSE := 0.20
# Mana Seed attack anim has its impact frame around 290ms in
# (160+65+65). Waiting that long after play_attack() syncs the slash
# arc + damage popup with the visible sword strike.
const BODY_ANIM_TO_IMPACT := 0.29
# Ranged / spell skills don't dash; instead the caster plays a cast
# anim in place, holds it for this long, then the effect spawns at the
# target. Slightly longer than melee impact so the spell reads as a
# "wind-up" rather than an instant cast.
const CAST_TO_IMPACT := 0.32
const DEFAULT_ATB_COST := 100.0

# Per-skill slash VFX variant. Maps a skill id to one of the animations
# defined in scenes/battle/slash_effect.tscn's SpriteFrames.
#   "slash1" — sharp horizontal cut (default; basic attacks)
#   "slash2" — wider aggressive arc (fire / heavy single-target)
#   "thrust" — tighter jab (piercing / debuff)
#   ""        — no slash spawned (SELF / heal skills)
const SKILL_TO_SLASH := {
	"basic_attack":   &"slash1",
	"flame_slash":    &"slash2",
	"shatter":        &"thrust",
	"pyre_breaker":   &"slash2",
	"crimson_blitz":  &"slash2",
	"enemy_basic":    &"slash1",
	"brace":          &"",
	"aegis":          &"",
	"mend":           &"",
}

# Per-skill BODY animation. Maps a skill id to a named animation in the
# hero's SpriteFrames.
#   "attack" — slash 1 (default basic attack)
#   "slash2" — wider/heavier swing
#   "thrust" — forward jab
#   "brace"  — east-facing crouch w/ shield up (defensive buffs)
#   "cast"   — upright guard pose (channeling heal / support)
#   ""       — no body anim (use scale puff only)
const SKILL_TO_BODY_ANIM := {
	"basic_attack":   &"attack",
	"flame_slash":    &"slash2",
	"shatter":        &"thrust",
	"pyre_breaker":   &"slash2",
	"crimson_blitz":  &"thrust",
	"enemy_basic":    &"attack",
	"brace":          &"brace",
	"aegis":          &"brace",
	"mend":           &"cast",
}

# Per-element slash tint. Indices match the HeroData / SkillData element
# enum: FIRE=0, WATER=1, EARTH=2, WIND=3, LIGHT=4, DARK=5. The slash
# sprite ships near-white, so these modulate colors paint the arc.
const ELEMENT_TINT := [
	Color(1.00, 0.55, 0.35, 1.0),  # FIRE  — orange-red
	Color(0.50, 0.85, 1.00, 1.0),  # WATER — cyan
	Color(0.95, 0.78, 0.45, 1.0),  # EARTH — amber-tan
	Color(0.65, 1.00, 0.75, 1.0),  # WIND  — pale green
	Color(1.00, 0.95, 0.55, 1.0),  # LIGHT — bright yellow
	Color(0.85, 0.55, 1.00, 1.0),  # DARK  — purple
]
# Fallback for unresolved / neutral slashes (matches the slash scene's
# original modulate so non-elemental swings look unchanged).
const SLASH_TINT_NEUTRAL := Color(1.0, 1.0, 0.85, 1.0)

# Slight color shifts so identical-data slimes are visually distinct.
const ENEMY_TINTS := [
	Color(0.45, 0.85, 0.55, 1),
	Color(0.55, 0.78, 0.42, 1),
	Color(0.40, 0.78, 0.62, 1),
]

@onready var _hero_units: Array[Node2D] = [
	$PlayerUnit0, $PlayerUnit1, $PlayerUnit2,
]
@onready var _enemy_units: Array[Node2D] = [
	$EnemyUnit0, $EnemyUnit1, $EnemyUnit2,
]
@onready var _turn_label: Label = $UI/TurnPanel/TurnLabel
@onready var _turn_order_bar: HBoxContainer = $UI/TurnOrderBar
@onready var _end_panel: ColorRect = $UI/EndPanel
@onready var _result_label: Label = $UI/EndPanel/EndVBox/ResultLabel
@onready var _popup_layer: Node2D = $PopupLayer
@onready var _camera: Camera2D = $Camera
@onready var _actions_hbox: HBoxContainer = $UI/ActionPanel/Actions
@onready var _ult_btn: Button = $UI/ActionPanel/Actions/UltBtn

signal _player_action_done

var _rng: SeededRNG
var _battle_over: bool = false
var _battle_id: String = ""

var _heroes_data: Array[HeroData] = []
var _heroes_stats: Array[Dictionary] = []
var _heroes_hp: Array[int] = []
var _atb_heroes: Array[float] = []

var _enemy_template: EnemyData
var _enemies_stats: Array[Dictionary] = []
var _enemies_hp: Array[int] = []
var _atb_enemies: Array[float] = []

var _skill_buttons: Array[Button] = []
var _active_hero_idx: int = -1
var _selected_enemy_idx: int = 0

# Re-entrancy guard for the crit slow-mo. Without it, AoE crits would
# stack time_scale assignments and the restoration of one could happen
# while another's still running.
var _crit_slowmo_active: bool = false


# ─── Setup ───────────────────────────────────────────────────────────

func _ready() -> void:
	Game.transition_state(Game.State.BATTLE)
	_battle_id = "%d" % Time.get_ticks_msec()
	_rng = SeededRNG.new(int(Time.get_unix_time_from_system()))

	_enemy_template = ContentRegistry.get_enemy(TEST_ENEMY_ID)
	if _enemy_template == null:
		_fail_setup("missing enemy: " + TEST_ENEMY_ID); return

	# Heroes — read from Game.selected_party_ids (Party Builder), with fallback
	var party_ids: Array = _resolve_party_ids()
	for i in HERO_COUNT:
		var hero_id: String = party_ids[i]
		var hero_data: HeroData = ContentRegistry.get_hero(hero_id)
		if hero_data == null:
			_fail_setup("missing hero: " + hero_id); return
		_heroes_data.append(hero_data)
		var stats := _hero_to_stats(hero_data)
		_heroes_stats.append(stats)
		_heroes_hp.append(int(stats.hp))
		_atb_heroes.append(0.0)
		var unit: Node2D = _hero_units[i]
		unit.bind(
			hero_data.display_name,
			hero_data.sprite_color,
			_heroes_hp[i],
			hero_data.idle_frames,
			hero_data.sprite_scale,
			hero_data.sprite_y_offset,
		)
		unit.set_targetable(false)   # ally-target UI is Phase 2f

	# Enemies
	for i in ENEMY_COUNT:
		var stats := _enemy_to_stats(_enemy_template)
		_enemies_stats.append(stats)
		_enemies_hp.append(int(stats.hp))
		_atb_enemies.append(0.0)
		var unit: Node2D = _enemy_units[i]
		var tint: Color = ENEMY_TINTS[i % ENEMY_TINTS.size()]
		# Use real sprite frames if the template provides them; tint becomes
		# the sprite_color fallback for entities without art yet.
		unit.bind(
			"%s %d" % [_enemy_template.display_name, i + 1],
			tint,
			int(stats.hp),
			_enemy_template.idle_frames,
			_enemy_template.sprite_scale,
			_enemy_template.sprite_y_offset,
		)
		unit.set_ultimate_visible(false)  # enemies don't have ultimates
		var captured_idx := i
		unit.clicked.connect(func(_u: Node2D): _on_enemy_clicked(captured_idx))
		unit.set_targetable(true)

	_setup_skill_buttons()
	_register_turn_order_units()
	_select_enemy(0)
	_refresh_turn_order_bar()

	_end_panel.hide()
	EventBus.combat_started.emit(_battle_id)
	print("[Battle] starting — 3v3 (seed=%d)" % _rng.rng.seed)
	_next_turn()


## Read the player's chosen party from Game.selected_party_ids, falling back
## to FALLBACK_PARTY_HERO_IDS for any slot that's empty/missing/unknown.
## Returns exactly HERO_COUNT entries.
func _resolve_party_ids() -> Array:
	var resolved: Array = []
	for i in HERO_COUNT:
		var id := ""
		if i < Game.selected_party_ids.size():
			id = String(Game.selected_party_ids[i])
		if id == "" or ContentRegistry.get_hero(id) == null:
			id = FALLBACK_PARTY_HERO_IDS[i]
		resolved.append(id)
	return resolved


func _setup_skill_buttons() -> void:
	_skill_buttons.clear()
	for i in MAX_SKILL_SLOTS:
		var btn: Button = _actions_hbox.get_node("SkillBtn%d" % i)
		_skill_buttons.append(btn)
		var idx := i
		btn.pressed.connect(func(): _on_skill_pressed(idx))
		btn.visible = false   # populated per-active-hero at turn start
	_ult_btn.pressed.connect(_on_ult_pressed)
	_ult_btn.disabled = true
	_ult_btn.visible = false


func _register_turn_order_units() -> void:
	for i in HERO_COUNT:
		var data: HeroData = _heroes_data[i]
		_turn_order_bar.register_unit(_hero_id(i), data.sprite_color, data.display_name)
	for i in ENEMY_COUNT:
		_turn_order_bar.register_unit(_enemy_id(i), ENEMY_TINTS[i % ENEMY_TINTS.size()], _enemy_template.display_name)


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


# ─── ID helpers ──────────────────────────────────────────────────────

func _hero_id(idx: int) -> String:
	return "%s#%d" % [_heroes_data[idx].id, idx]


func _enemy_id(idx: int) -> String:
	return "%s#%d" % [_enemy_template.id, idx]


func _idx_for_hero_id(id: String) -> int:
	for i in HERO_COUNT:
		if _hero_id(i) == id:
			return i
	return -1


func _idx_for_enemy_id(id: String) -> int:
	for i in ENEMY_COUNT:
		if _enemy_id(i) == id:
			return i
	return -1


# ─── Selection / targeting ───────────────────────────────────────────

func _on_enemy_clicked(idx: int) -> void:
	if _battle_over: return
	if idx < 0 or idx >= ENEMY_COUNT: return
	if _enemies_hp[idx] <= 0: return
	_select_enemy(idx)


func _select_enemy(idx: int) -> void:
	if _enemies_hp[idx] <= 0:
		idx = _first_alive_enemy_idx()
		if idx < 0: return
	_selected_enemy_idx = idx
	for i in ENEMY_COUNT:
		_enemy_units[i].set_selected(i == idx and _enemies_hp[i] > 0)


func _set_active_hero(idx: int) -> void:
	_active_hero_idx = idx
	for i in HERO_COUNT:
		_hero_units[i].set_active(i == idx and _heroes_hp[i] > 0)


func _first_alive_enemy_idx() -> int:
	for i in ENEMY_COUNT:
		if _enemies_hp[i] > 0:
			return i
	return -1


func _alive_enemy_count() -> int:
	var c := 0
	for hp in _enemies_hp:
		if hp > 0: c += 1
	return c


func _alive_hero_count() -> int:
	var c := 0
	for hp in _heroes_hp:
		if hp > 0: c += 1
	return c


func _pick_alive_hero_idx() -> int:
	var alive: Array[int] = []
	for i in HERO_COUNT:
		if _heroes_hp[i] > 0:
			alive.append(i)
	if alive.is_empty(): return -1
	return alive[_rng.range_int(0, alive.size() - 1)]


# ─── ATB ─────────────────────────────────────────────────────────────

func _atb_states() -> Array:
	var states: Array = []
	for i in HERO_COUNT:
		var p_eff := _effective_stats(_heroes_stats[i], _hero_units[i].statuses)
		states.append({
			"id": _hero_id(i), "atb": _atb_heroes[i],
			"spd": float(p_eff.spd), "alive": _heroes_hp[i] > 0,
		})
	for i in ENEMY_COUNT:
		var e_eff := _effective_stats(_enemies_stats[i], _enemy_units[i].statuses)
		states.append({
			"id": _enemy_id(i), "atb": _atb_enemies[i],
			"spd": float(e_eff.spd), "alive": _enemies_hp[i] > 0,
		})
	return states


func _commit_atb(new_states: Array) -> void:
	for s in new_states:
		var h_idx: int = _idx_for_hero_id(s.id)
		if h_idx >= 0:
			_atb_heroes[h_idx] = float(s.atb)
			continue
		var e_idx: int = _idx_for_enemy_id(s.id)
		if e_idx >= 0:
			_atb_enemies[e_idx] = float(s.atb)


func _refresh_turn_order_bar() -> void:
	var seq: Array = ATBScheduler.predict_sequence(_atb_states(), 5)
	_turn_order_bar.set_sequence(seq)


# ─── Main loop ───────────────────────────────────────────────────────

func _next_turn() -> void:
	if _battle_over: return
	var step: Dictionary = ATBScheduler.next_actor(_atb_states())
	if step.is_empty(): return
	_commit_atb(step.new_states)
	_refresh_turn_order_bar()

	var actor_id: String = step.actor_id
	var h_idx: int = _idx_for_hero_id(actor_id)
	var e_idx: int = _idx_for_enemy_id(actor_id)
	if h_idx >= 0:
		await _do_hero_turn(h_idx)
	elif e_idx >= 0:
		await _do_enemy_turn(e_idx)

	if _battle_over: return
	_next_turn()


# ─── Hero turn ───────────────────────────────────────────────────────

func _do_hero_turn(idx: int) -> void:
	_set_active_hero(idx)
	var hero_data: HeroData = _heroes_data[idx]
	var hero_unit: Node2D = _hero_units[idx]

	if hero_unit.statuses.is_stunned():
		_turn_label.text = "%s — stunned" % hero_data.display_name
		_spawn_text_popup(hero_unit.get_anchor(&"above"), "STUNNED", Color(0.95, 0.85, 0.3))
		await get_tree().create_timer(0.7).timeout
		_atb_heroes[idx] = max(0.0, _atb_heroes[idx] - DEFAULT_ATB_COST)
	else:
		if _enemies_hp[_selected_enemy_idx] <= 0:
			_select_enemy(0)
		_populate_skill_buttons_for_hero(idx)
		_turn_label.text = "%s — your move" % hero_data.display_name
		_set_actions_enabled(true)
		await _player_action_done

	_set_active_hero(-1)
	await _tick_unit_statuses_hero(idx)
	_check_end_battle()


func _populate_skill_buttons_for_hero(idx: int) -> void:
	var hero_data: HeroData = _heroes_data[idx]
	for i in MAX_SKILL_SLOTS:
		var btn: Button = _skill_buttons[i]
		if i < hero_data.skill_ids.size():
			var s: SkillData = ContentRegistry.get_skill(hero_data.skill_ids[i])
			btn.text = s.skill_name if s != null else "?"
			btn.tooltip_text = s.description if s != null else ""
			btn.visible = true
			btn.disabled = true
		else:
			btn.visible = false
	# Ultimate button
	if hero_data.ultimate_id != "":
		var ult: SkillData = ContentRegistry.get_skill(hero_data.ultimate_id)
		if ult != null:
			_ult_btn.text = ult.skill_name
			_ult_btn.tooltip_text = ult.description
			_ult_btn.visible = true
		else:
			_ult_btn.visible = false
	else:
		_ult_btn.visible = false


func _set_actions_enabled(enabled: bool) -> void:
	for btn in _skill_buttons:
		if btn.visible:
			btn.disabled = not enabled
	if _ult_btn.visible and _active_hero_idx >= 0:
		var ready: bool = _hero_units[_active_hero_idx].is_ultimate_ready()
		_ult_btn.disabled = not (enabled and ready)
	else:
		_ult_btn.disabled = true


func _on_skill_pressed(idx: int) -> void:
	if _battle_over: return
	if _active_hero_idx < 0: return
	var hero_data: HeroData = _heroes_data[_active_hero_idx]
	if idx >= hero_data.skill_ids.size(): return
	_set_actions_enabled(false)
	var skill_id: String = hero_data.skill_ids[idx]
	var skill: SkillData = ContentRegistry.get_skill(skill_id)
	if skill == null:
		push_error("[Battle] missing skill: " + skill_id)
		_set_actions_enabled(true); return
	await _hero_uses_skill(skill, _active_hero_idx)
	var cost: float = float(skill.atb_cost) if skill.atb_cost > 0 else DEFAULT_ATB_COST
	_atb_heroes[_active_hero_idx] = max(0.0, _atb_heroes[_active_hero_idx] - cost)
	_refresh_turn_order_bar()
	_player_action_done.emit()


func _on_ult_pressed() -> void:
	if _battle_over: return
	if _active_hero_idx < 0: return
	var hero_data: HeroData = _heroes_data[_active_hero_idx]
	if hero_data.ultimate_id == "": return
	var hero_unit: Node2D = _hero_units[_active_hero_idx]
	if not hero_unit.is_ultimate_ready(): return
	var ult: SkillData = ContentRegistry.get_skill(hero_data.ultimate_id)
	if ult == null:
		push_error("[Battle] missing ultimate: " + hero_data.ultimate_id); return
	_set_actions_enabled(false)
	print("[Battle] %s -> ULTIMATE %s" % [_hero_id(_active_hero_idx), ult.id])
	var hero_idx := _active_hero_idx
	var caster := _hero_units[hero_idx]
	# Cinematic cut-in: dim overlay + slanted accent + ult/caster banner.
	# Awaits the cut-in's `done` signal so the actual swing only starts
	# once the banner has cleared.
	await _play_ult_cutin(ult.skill_name, hero_data.display_name, hero_data.sprite_color)
	# Dramatic pulse on the caster just before the swing, so the ult
	# moment lands with weight even after the cut-in.
	var pre := create_tween()
	pre.tween_property(caster, "scale", Vector2(1.22, 1.22), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pre.tween_property(caster, "scale", Vector2(1.0, 1.0), 0.16)
	await get_tree().create_timer(0.22).timeout
	await _hero_uses_skill(ult, hero_idx)
	var cost: float = float(ult.atb_cost) if ult.atb_cost > 0 else DEFAULT_ATB_COST
	_atb_heroes[hero_idx] = max(0.0, _atb_heroes[hero_idx] - cost)
	caster.reset_ultimate()
	_refresh_turn_order_bar()
	_player_action_done.emit()


func _hero_uses_skill(skill: SkillData, hero_idx: int) -> void:
	match skill.target_type:
		4:  # SELF
			await _resolve_skill_self(skill, hero_idx)
		1:  # ENEMY_ALL
			await _resolve_skill_enemy_all(skill, hero_idx)
		_:  # ENEMY_SINGLE (default)
			if _enemies_hp[_selected_enemy_idx] <= 0:
				_select_enemy(0)
				if _enemies_hp[_selected_enemy_idx] <= 0: return
			await _resolve_skill_enemy_single(skill, hero_idx, _selected_enemy_idx)


func _resolve_skill_self(skill: SkillData, hero_idx: int) -> void:
	var hero_unit: Node2D = _hero_units[hero_idx]
	var hero_stats: Dictionary = _heroes_stats[hero_idx]
	# Body pose (crouch for Brace/Aegis, guard-up for Mend). play_attack
	# is a no-op for &"" and the animation auto-returns to idle when done.
	var body_anim: StringName = SKILL_TO_BODY_ANIM.get(skill.id, &"")
	hero_unit.play_attack(body_anim)
	var puff := create_tween()
	puff.tween_property(hero_unit, "scale", Vector2(1.06, 1.06), 0.10)
	puff.tween_property(hero_unit, "scale", Vector2(1.0, 1.0), 0.18)
	# Hold the pose a beat before applying the effect so the brace / cast
	# stance is clearly visible before the status icon / heal popup lands.
	await get_tree().create_timer(0.30).timeout
	var attacker_eff := _effective_stats(hero_stats, hero_unit.statuses)
	var target_eff := _effective_stats(hero_stats, hero_unit.statuses)
	await _resolve_skill(skill, attacker_eff, target_eff, _hero_id(hero_idx), _hero_id(hero_idx), hero_unit, hero_idx, true)
	await get_tree().create_timer(0.45).timeout


func _resolve_skill_enemy_single(skill: SkillData, hero_idx: int, target_idx: int) -> void:
	var hero_unit: Node2D = _hero_units[hero_idx]
	var hero_stats: Dictionary = _heroes_stats[hero_idx]
	var target_unit: Node2D = _enemy_units[target_idx]
	var body_anim: StringName = SKILL_TO_BODY_ANIM.get(skill.id, &"attack")
	var attacker_eff := _effective_stats(hero_stats, hero_unit.statuses)
	var target_eff := _effective_stats(_enemies_stats[target_idx], target_unit.statuses)
	var resolve := func():
		await _resolve_skill(skill, attacker_eff, target_eff,
			_hero_id(hero_idx), _enemy_id(target_idx), target_unit, target_idx, false)

	if skill.requires_approach:
		await _melee_attack(hero_unit, target_unit.global_position, body_anim, resolve)
	else:
		await _ranged_cast(hero_unit, body_anim, resolve)


func _resolve_skill_enemy_all(skill: SkillData, hero_idx: int) -> void:
	var hero_unit: Node2D = _hero_units[hero_idx]
	var hero_stats: Dictionary = _heroes_stats[hero_idx]
	var alive_idxs: Array[int] = []
	for i in ENEMY_COUNT:
		if _enemies_hp[i] > 0:
			alive_idxs.append(i)
	if alive_idxs.is_empty(): return

	# Lunge toward centroid of alive enemies for the AoE swing
	var centroid := Vector2.ZERO
	for i in alive_idxs:
		centroid += _enemy_units[i].global_position
	centroid /= alive_idxs.size()
	var body_anim: StringName = SKILL_TO_BODY_ANIM.get(skill.id, &"attack")
	var attacker_eff := _effective_stats(hero_stats, hero_unit.statuses)
	# AoE resolve fires on every alive enemy with the same swing.
	var resolve := func():
		for i in alive_idxs:
			var target_unit: Node2D = _enemy_units[i]
			var target_eff := _effective_stats(_enemies_stats[i], target_unit.statuses)
			await _resolve_skill(skill, attacker_eff, target_eff,
				_hero_id(hero_idx), _enemy_id(i), target_unit, i, false)

	if skill.requires_approach:
		await _melee_attack(hero_unit, centroid, body_anim, resolve)
	else:
		await _ranged_cast(hero_unit, body_anim, resolve)


# ─── Enemy turn ──────────────────────────────────────────────────────

func _do_enemy_turn(idx: int) -> void:
	var enemy_unit: Node2D = _enemy_units[idx]
	var enemy_stats: Dictionary = _enemies_stats[idx]
	_turn_label.text = "%s %d moves" % [_enemy_template.display_name, idx + 1]
	await get_tree().create_timer(0.35).timeout

	if enemy_unit.statuses.is_stunned():
		_spawn_text_popup(enemy_unit.get_anchor(&"above"), "STUNNED", Color(0.95, 0.85, 0.3))
		await get_tree().create_timer(0.7).timeout
	else:
		var target_hero_idx: int = _pick_alive_hero_idx()
		if target_hero_idx < 0:
			# Shouldn't happen — battle should have ended. Bail.
			_atb_enemies[idx] = max(0.0, _atb_enemies[idx] - DEFAULT_ATB_COST)
			return
		var target_hero: Node2D = _hero_units[target_hero_idx]

		var enemy_skill := _make_enemy_skill(idx)
		var attacker_eff := _effective_stats(enemy_stats, enemy_unit.statuses)
		var target_eff := _effective_stats(_heroes_stats[target_hero_idx], target_hero.statuses)
		var resolve := func():
			await _resolve_skill(enemy_skill, attacker_eff, target_eff,
				_enemy_id(idx), _hero_id(target_hero_idx), target_hero, target_hero_idx, true)

		if enemy_skill.requires_approach:
			await _melee_attack(enemy_unit, target_hero.global_position, &"attack", resolve)
		else:
			await _ranged_cast(enemy_unit, &"attack", resolve)

	_atb_enemies[idx] = max(0.0, _atb_enemies[idx] - DEFAULT_ATB_COST)
	_refresh_turn_order_bar()

	await _tick_unit_statuses_enemy(idx)
	_check_end_battle()


func _make_enemy_skill(idx: int) -> SkillData:
	var skill := SkillData.new()
	skill.id = "enemy_basic"
	skill.skill_name = "Slam"
	skill.element = int(_enemies_stats[idx].element)
	skill.target_type = 0
	skill.atb_cost = 100
	var dmg := EffectDamage.new()
	dmg.power_mult = _enemy_template.attack_power
	dmg.hits = 1
	skill.effects = [dmg]
	return skill


# ─── Effect resolution ───────────────────────────────────────────────

func _resolve_skill(skill: SkillData, attacker_stats: Dictionary, target_stats: Dictionary, attacker_id: String, target_id: String, target_unit: Node2D, target_idx: int, target_is_hero: bool) -> void:
	var slash_variant: StringName = SKILL_TO_SLASH.get(skill.id, &"slash1")
	# Resolve the element once per skill cast so the slash tint and the
	# element burst VFX stay in sync. -1 means "no element" (neutral
	# slash, no burst spawned).
	var element: int = _resolve_element(skill, attacker_stats)
	var slash_tint: Color = ELEMENT_TINT[element] if element >= 0 and element < ELEMENT_TINT.size() else SLASH_TINT_NEUTRAL
	for effect in skill.effects:
		var ctx := EffectContext.new(attacker_stats, target_stats, attacker_id, target_id, skill, _rng)
		var result: Dictionary = effect.apply(ctx)
		_apply_result(result, attacker_id, target_id, target_unit, target_idx, target_is_hero, slash_variant, slash_tint, element)
		if result.get("kind") == "miss":
			break


## Pick the element for a single skill cast: skill.element overrides
## (>= 0), otherwise inherit from the caster's element stat. Returns -1
## if there's no element at all — neutral attack, no burst VFX.
func _resolve_element(skill: SkillData, attacker_stats: Dictionary) -> int:
	if skill.element >= 0:
		return skill.element
	if attacker_stats.has("element"):
		return int(attacker_stats["element"])
	return -1


func _apply_result(result: Dictionary, attacker_id: String, target_id: String, target_unit: Node2D, target_idx: int, target_is_hero: bool, slash_variant: StringName = &"slash1", slash_tint: Color = Color(1.0, 1.0, 0.85, 1.0), element: int = -1) -> void:
	match result.get("kind", "none"):
		"damage":
			var amount: int = int(result.damage)
			var target_max_hp: int
			var killed: bool = false
			if target_is_hero:
				_heroes_hp[target_idx] = max(0, _heroes_hp[target_idx] - amount)
				target_max_hp = int(_heroes_stats[target_idx].hp)
				target_unit.set_hp(_heroes_hp[target_idx], target_max_hp)
				if _heroes_hp[target_idx] <= 0:
					target_unit.set_dead(true)
					killed = true
			else:
				_enemies_hp[target_idx] = max(0, _enemies_hp[target_idx] - amount)
				target_max_hp = int(_enemies_stats[target_idx].hp)
				target_unit.set_hp(_enemies_hp[target_idx], target_max_hp)
				if _enemies_hp[target_idx] <= 0:
					target_unit.set_dead(true)
					killed = true
					if _selected_enemy_idx == target_idx:
						_select_enemy(0)
			# Play hurt recoil if the unit survived the hit (dead anim plays via set_dead)
			if not killed:
				target_unit.play_hurt()
			_spawn_popup(target_unit.get_anchor(&"over_head"), amount, result.is_crit, result.is_lucky)
			# Slash arc bulges toward the side the sword came FROM.
			# Attacker to the LEFT of target  -> slash bulges left -> flipped = true (mirror default texture)
			# Attacker to the RIGHT of target -> slash bulges right -> flipped = false
			var flipped: bool = target_unit.global_position.x > _attacker_x(attacker_id)
			var slash_x: int = -20 if flipped else 20
			if slash_variant != &"":
				# Anchor the slash at the target's center, with a small
				# horizontal nudge in the direction the sword came from.
				_spawn_slash(target_unit.get_anchor(&"center") + Vector2(slash_x, 0), flipped, slash_variant, slash_tint)
			# Element burst sits on top of the slash arc — pixel-art
			# fireball / splash / shard / swoosh per element. Only
			# spawned when the element has a shipped pack (0..3).
			if element >= 0 and element <= 3:
				_spawn_element_burst(target_unit.get_anchor(&"center"), element)
			if result.is_crit:
				_shake_camera(14.0, 0.24)
				_crit_punch()
			else:
				_shake_camera(6.0, 0.14)
			EventBus.damage_dealt.emit(attacker_id, target_id, amount, result.is_crit)
			# Ultimate gauge: attacker gains for damage dealt, target for damage taken.
			# Only heroes have ult gauges; enemies are ignored.
			_award_gauge_dealt(attacker_id, amount, target_max_hp)
			_award_gauge_taken(target_id, target_unit, amount, target_max_hp)
			print("[Battle] %s -> %s : %d dmg (crit=%s lucky=%s elem=%.1fx)" % [
				attacker_id, target_id, amount, result.is_crit, result.is_lucky, result.elemental_mult,
			])
		"miss":
			_spawn_text_popup(target_unit.get_anchor(&"over_head"), "MISS", Color(0.7, 0.7, 0.7))
			print("[Battle] %s -> %s MISSED" % [attacker_id, target_id])
		"status":
			var data: StatusEffectData = ContentRegistry.get_status(result.status_id)
			if data == null:
				push_error("[Battle] missing status: " + str(result.status_id)); return
			target_unit.add_status(result.status_id, result.duration, result.power, data)
			_spawn_text_popup(target_unit.get_anchor(&"above"), data.display_name.to_upper(), data.icon_color)
			_spawn_status_vfx(target_unit, data)
			EventBus.status_applied.emit(target_id, result.status_id)
		"status_resisted":
			_spawn_text_popup(target_unit.get_anchor(&"above"), "RESIST", Color(0.6, 0.8, 1.0))
		"heal":
			var amount: int = int(result.amount)
			if target_is_hero:
				_heroes_hp[target_idx] = min(int(_heroes_stats[target_idx].hp), _heroes_hp[target_idx] + amount)
				target_unit.set_hp(_heroes_hp[target_idx], int(_heroes_stats[target_idx].hp))
			else:
				_enemies_hp[target_idx] = min(int(_enemies_stats[target_idx].hp), _enemies_hp[target_idx] + amount)
				target_unit.set_hp(_enemies_hp[target_idx], int(_enemies_stats[target_idx].hp))
			_spawn_text_popup(target_unit.get_anchor(&"over_head"), "+%d" % amount, Color(0.4, 0.85, 0.4))
			_spawn_heal_vfx(target_unit)
		"none":
			pass


## Award ultimate gauge to the attacker (a hero) proportional to damage dealt.
## Capped per-hit. Enemies don't have an ult gauge, silently no-op.
func _award_gauge_dealt(attacker_id: String, damage: int, target_max_hp: int) -> void:
	var h_idx: int = _idx_for_hero_id(attacker_id)
	if h_idx < 0: return
	var gain: float = clamp(float(damage) / float(max(target_max_hp, 1)) * 60.0, 0.0, 35.0)
	_hero_units[h_idx].add_ultimate(gain)


## Award ultimate gauge to the target unit (a hero) for damage taken.
func _award_gauge_taken(target_id: String, target_unit: Node2D, damage: int, max_hp: int) -> void:
	var h_idx: int = _idx_for_hero_id(target_id)
	if h_idx < 0: return
	var gain: float = clamp(float(damage) / float(max(max_hp, 1)) * 75.0, 0.0, 40.0)
	target_unit.add_ultimate(gain)


## Look up the attacker's world X so the slash arc faces the right way
## regardless of which hero / enemy is the attacker.
func _attacker_x(attacker_id: String) -> float:
	var h_idx: int = _idx_for_hero_id(attacker_id)
	if h_idx >= 0:
		return _hero_units[h_idx].global_position.x
	var e_idx: int = _idx_for_enemy_id(attacker_id)
	if e_idx >= 0:
		return _enemy_units[e_idx].global_position.x
	return 0.0


# ─── Status ticks ────────────────────────────────────────────────────

func _tick_unit_statuses_hero(idx: int) -> void:
	var unit: Node2D = _hero_units[idx]
	var stats: Dictionary = _heroes_stats[idx]
	var results: Array = unit.statuses.tick_end_of_turn(stats)
	for result in results:
		match result.get("kind"):
			"tick_damage":
				var amount: int = int(result.amount)
				_heroes_hp[idx] = max(0, _heroes_hp[idx] - amount)
				unit.set_hp(_heroes_hp[idx], int(stats.hp))
				_spawn_dot_popup(unit.get_anchor(&"over_head"), amount, result.status_id)
				if _heroes_hp[idx] <= 0:
					unit.set_dead(true)
				await get_tree().create_timer(0.20).timeout
	unit.refresh_status_durations()
	_refresh_turn_order_bar()


func _tick_unit_statuses_enemy(idx: int) -> void:
	var unit: Node2D = _enemy_units[idx]
	var stats: Dictionary = _enemies_stats[idx]
	var results: Array = unit.statuses.tick_end_of_turn(stats)
	for result in results:
		match result.get("kind"):
			"tick_damage":
				var amount: int = int(result.amount)
				_enemies_hp[idx] = max(0, _enemies_hp[idx] - amount)
				unit.set_hp(_enemies_hp[idx], int(stats.hp))
				_spawn_dot_popup(unit.get_anchor(&"over_head"), amount, result.status_id)
				if _enemies_hp[idx] <= 0:
					unit.set_dead(true)
					if _selected_enemy_idx == idx:
						_select_enemy(0)
				await get_tree().create_timer(0.20).timeout
	unit.refresh_status_durations()
	_refresh_turn_order_bar()


func _spawn_dot_popup(at: Vector2, amount: int, status_id: String) -> void:
	var data: StatusEffectData = ContentRegistry.get_status(status_id)
	var color: Color = data.icon_color if data != null else Color(0.9, 0.55, 0.3)
	var popup := POPUP_SCENE.instantiate()
	_popup_layer.add_child(popup)
	popup.global_position = at
	popup.show_text(str(amount), color, 22)


# ─── End-of-battle ───────────────────────────────────────────────────

func _check_end_battle() -> bool:
	if _alive_enemy_count() == 0:
		_end_battle(true); return true
	if _alive_hero_count() == 0:
		_end_battle(false); return true
	return false


func _end_battle(victory: bool) -> void:
	if _battle_over: return
	_battle_over = true
	_set_actions_enabled(false)
	for u in _enemy_units:
		u.set_targetable(false)
		u.set_selected(false)
	for u in _hero_units:
		u.set_active(false)
	_result_label.text = "VICTORY" if victory else "DEFEAT"
	_result_label.add_theme_color_override(
		"font_color",
		Color(0.97, 0.78, 0.31) if victory else Color(0.93, 0.35, 0.4),
	)
	_end_panel.show()
	EventBus.combat_ended.emit(_battle_id, victory)
	print("[Battle] ended — ", "VICTORY" if victory else "DEFEAT")


# ─── VFX helpers ─────────────────────────────────────────────────────

## Dash the unit toward a target position, stopping APPROACH_GAP short.
## Returns { "origin": Vector2, "dur": float } so the caller can later
## call _dash_back to return the unit to its original spot.
##
## Duration scales with distance via DASH_SPEED (clamped to
## DASH_DUR_MIN / DASH_DUR_MAX) so near and far attacks feel like the
## same physical motion.
func _dash_to(unit: Node2D, toward: Vector2) -> Dictionary:
	var origin: Vector2 = unit.position
	var to_target: Vector2 = toward - unit.global_position
	var dir: Vector2 = to_target.normalized()
	var travel: float = max(0.0, to_target.length() - APPROACH_GAP)
	var dur: float = clamp(travel / DASH_SPEED, DASH_DUR_MIN, DASH_DUR_MAX)
	var target: Vector2 = origin + dir * travel
	var tween := create_tween()
	tween.tween_property(unit, "position", target, dur) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	return {"origin": origin, "dur": dur}


## Slide the unit back to a previously captured origin at the same dash
## duration. Caller awaits dur after this returns.
func _dash_back(unit: Node2D, origin: Vector2, dur: float) -> void:
	var tween := create_tween()
	tween.tween_property(unit, "position", origin, dur) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


## Melee attack beat:
##   dash forward -> halt -> body anim + resolve_effect -> halt -> dash back.
## `resolve_fn` is a Callable that fires the slash arc, damage popups,
## and any per-target effects — it runs after the body anim's impact
## frame is showing. Used by both heroes and enemies, single-target and
## AoE (the caller passes the centroid for AoE).
func _melee_attack(attacker: Node2D, toward: Vector2, body_anim: StringName, resolve_fn: Callable) -> void:
	var dash := _dash_to(attacker, toward)
	await get_tree().create_timer(dash.dur).timeout
	await get_tree().create_timer(IMPACT_PRE_PAUSE).timeout

	attacker.play_attack(body_anim)
	await get_tree().create_timer(BODY_ANIM_TO_IMPACT).timeout
	await resolve_fn.call()

	await get_tree().create_timer(IMPACT_POST_PAUSE).timeout
	_dash_back(attacker, dash.origin, dash.dur)
	await get_tree().create_timer(dash.dur).timeout


## Ranged / spell beat:
##   stay at origin -> cast anim -> wait CAST_TO_IMPACT -> resolve at
##   target -> halt. No dash. Use for spells, ranged shots, or any
##   skill that should fire from far away.
##
## When projectile system arrives, this is where the projectile tween
## from attacker.head -> target.center would live (before resolve_fn).
func _ranged_cast(attacker: Node2D, body_anim: StringName, resolve_fn: Callable) -> void:
	attacker.play_attack(body_anim)
	await get_tree().create_timer(CAST_TO_IMPACT).timeout
	await resolve_fn.call()
	await get_tree().create_timer(IMPACT_POST_PAUSE).timeout


func _spawn_slash(at: Vector2, flipped: bool, variant: StringName = &"slash1", tint: Color = SLASH_TINT_NEUTRAL) -> void:
	var effect := SLASH_SCENE.instantiate()
	_popup_layer.add_child(effect)
	effect.global_position = at
	effect.set_flipped(flipped)
	effect.set_tint(tint)
	effect.play_variant(variant)


## Pick the buff vs debuff VFX from the status's modifier sign.
##   modifier_amount > 0  -> buff (gold ring + sparkles)
##   anything else (negative modifier, DoT tick, stun) -> debuff
## (heal lands as a "heal" result, not a status, so it routes through
## _spawn_heal_vfx separately).
func _spawn_status_vfx(target_unit: Node2D, data: StatusEffectData) -> void:
	var is_buff: bool = data.modifier_amount > 0.0 \
		and data.tick_kind == StatusEffectData.TickKind.NONE \
		and not data.skip_turn
	var scene: PackedScene = BUFF_VFX_SCENE if is_buff else DEBUFF_VFX_SCENE
	var effect := scene.instantiate()
	_popup_layer.add_child(effect)
	# Anchor at the head so the ring frames the upper body, independent
	# of sprite scale (heroes vs goblins).
	effect.global_position = target_unit.get_anchor(&"head")


func _spawn_heal_vfx(target_unit: Node2D) -> void:
	var effect := HEAL_VFX_SCENE.instantiate()
	_popup_layer.add_child(effect)
	# Center on the torso — shimmer rises from there through the head.
	effect.global_position = target_unit.get_anchor(&"center")


func _spawn_element_burst(at: Vector2, element: int) -> void:
	var burst := ELEMENT_BURST_SCENE.instantiate()
	_popup_layer.add_child(burst)
	burst.global_position = at
	burst.play_element(element)


## Spawn the ultimate cut-in overlay, hand it the ult/caster names, and
## await the `done` signal so the caller pauses until the banner clears.
func _play_ult_cutin(ult_name: String, caster_name: String, accent_color: Color) -> void:
	var cutin := ULT_CUTIN_SCENE.instantiate()
	add_child(cutin)
	cutin.play(ult_name, caster_name, accent_color)
	await cutin.done


## Crit punch-up — brief Engine.time_scale dip so a critical hit
## visibly "stops the world" for a beat. Bigger camera shake fires
## alongside this from the call site.
##
## Gated by _crit_slowmo_active so back-to-back crits (Pyre Breaker AoE
## on three goblins, all crit) don't double-set time_scale and leave
## it stuck.
func _crit_punch() -> void:
	if _crit_slowmo_active:
		return
	_crit_slowmo_active = true
	Engine.time_scale = 0.4
	# `ignore_time_scale = true` (4th arg) so the wait runs at wall
	# time — otherwise the timer would itself be slowed and we'd be
	# stuck in slow-mo for 0.3s instead of 0.12s.
	await get_tree().create_timer(0.12, true, false, true).timeout
	Engine.time_scale = 1.0
	_crit_slowmo_active = false


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
