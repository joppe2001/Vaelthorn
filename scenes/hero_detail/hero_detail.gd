extends Control
## Phase 3a — Hero Detail panel.
##
## Reads Game.current_detail_hero_id and renders a stats sheet, skill list,
## and lore for that hero. Back button returns to the roster.

const ELEMENT_NAMES := ["FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK"]
const CLASS_NAMES := ["ATTACKER", "DEFENDER", "HEALER", "BUFFER", "DEBUFFER", "RANGER"]
const ELEMENT_COLORS := [
	Color(0.97, 0.55, 0.22, 1),
	Color(0.27, 0.55, 0.88, 1),
	Color(0.36, 0.70, 0.42, 1),
	Color(0.78, 0.88, 0.96, 1),
	Color(0.99, 0.83, 0.26, 1),
	Color(0.48, 0.30, 0.73, 1),
]

@onready var _heading: Label = $TopBar/Heading
@onready var _portrait: Control = $Layout/Portrait
@onready var _sub_label: Label = $Layout/Right/SubLabel
@onready var _stats_grid: GridContainer = $Layout/Right/StatsGrid
@onready var _skills_vbox: VBoxContainer = $Layout/Right/SkillsScroll/SkillsVBox
@onready var _lore_label: Label = $Lore

# Cached so the level-up panel can rebuild itself on every action.
var _current_hero: HeroData = null
var _progression_panel: PanelContainer = null


func _ready() -> void:
	Game.transition_state(Game.State.DETAIL)
	_current_hero = ContentRegistry.get_hero(Game.current_detail_hero_id)
	if _current_hero == null:
		_heading.text = "Hero not found"
		return
	_populate(_current_hero)


func _populate(hero: HeroData) -> void:
	_heading.text = hero.display_name
	# Portrait node may be TextureRect (current) or ColorRect (legacy fallback).
	if _portrait is TextureRect:
		(_portrait as TextureRect).texture = hero.portrait
	elif _portrait is ColorRect:
		(_portrait as ColorRect).color = hero.sprite_color

	var elem_name: String = ELEMENT_NAMES[hero.element] if hero.element >= 0 and hero.element < ELEMENT_NAMES.size() else "?"
	var class_name_str: String = CLASS_NAMES[hero.class_type] if hero.class_type >= 0 and hero.class_type < CLASS_NAMES.size() else "?"
	_sub_label.text = "%s  •  %s" % [elem_name, class_name_str]
	_sub_label.add_theme_color_override(
		"font_color",
		ELEMENT_COLORS[hero.element] if hero.element >= 0 and hero.element < ELEMENT_COLORS.size() else Color.WHITE,
	)

	_populate_stats(hero)
	_populate_skills(hero)
	_lore_label.text = hero.lore
	# Progression panel sits at the top of the Right column so the
	# player sees level + XP + level-up controls first.
	_rebuild_progression_panel()


func _populate_stats(hero: HeroData) -> void:
	for child in _stats_grid.get_children():
		child.queue_free()
	var rows := [
		["HP",         "%d" % hero.base_hp],
		["ATK",        "%d" % hero.base_atk],
		["DEF",        "%d" % hero.base_def],
		["SPD",        "%d" % hero.base_spd],
		["CRIT",       "%d%% / %.1fx" % [int(hero.base_crit_rate * 100), hero.base_crit_dmg]],
		["ACC / EVA",  "%d%% / %d%%" % [int(hero.base_acc * 100), int(hero.base_eva * 100)]],
		["LUK",        "%d" % hero.base_luk],
		["RES",        "%d%%" % int(hero.base_res * 100)],
	]
	for row in rows:
		var key := Label.new()
		key.text = row[0]
		key.add_theme_color_override("font_color", Color(0.6, 0.7, 0.78, 1))
		key.add_theme_font_size_override("font_size", 14)
		_stats_grid.add_child(key)
		var value := Label.new()
		value.text = row[1]
		value.add_theme_color_override("font_color", Color(0.957, 0.957, 0.957, 1))
		value.add_theme_font_size_override("font_size", 14)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_stats_grid.add_child(value)


func _populate_skills(hero: HeroData) -> void:
	for child in _skills_vbox.get_children():
		child.queue_free()
	for skill_id in hero.skill_ids:
		var skill: SkillData = ContentRegistry.get_skill(skill_id)
		if skill == null: continue
		_skills_vbox.add_child(_make_skill_row(skill, false))
	if hero.ultimate_id != "":
		var ult: SkillData = ContentRegistry.get_skill(hero.ultimate_id)
		if ult != null:
			_skills_vbox.add_child(_make_skill_row(ult, true))


func _make_skill_row(skill: SkillData, is_ult: bool) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.107, 0.107, 0.16, 1) if not is_ult else Color(0.25, 0.18, 0.07, 1)
	sb.border_color = Color(0.337, 0.424, 0.525, 1) if not is_ult else Color(0.976, 0.78, 0.31, 1)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	p.add_child(v)

	var name_label := Label.new()
	name_label.text = ("ULT • " if is_ult else "") + skill.skill_name
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override(
		"font_color",
		Color(0.976, 0.78, 0.31, 1) if is_ult else Color(0.957, 0.957, 0.957, 1),
	)
	v.add_child(name_label)

	var desc := Label.new()
	desc.text = skill.description
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 1))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(desc)

	return p


func _on_back_pressed() -> void:
	Game.change_scene("res://scenes/hero_roster/hero_roster.tscn")


# ─── Progression panel ───────────────────────────────────────────────

## Tear down (if present) and rebuild the level-up panel. Called after
## every potion use so the level, XP bar, owned counts, and gold-cost
## states refresh together.
func _rebuild_progression_panel() -> void:
	if _current_hero == null:
		return
	if _progression_panel != null and is_instance_valid(_progression_panel):
		_progression_panel.queue_free()
	_progression_panel = _build_progression_panel(_current_hero)
	var right: Control = _stats_grid.get_parent()
	right.add_child(_progression_panel)
	right.move_child(_progression_panel, 1)  # after SubLabel, before StatsGrid


func _build_progression_panel(hero: HeroData) -> PanelContainer:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.17, 1)
	sb.border_color = Color(0.337, 0.424, 0.525, 1)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)

	var progress: Dictionary = SaveManager.get_hero_progress(hero.id)
	var lvl: int = int(progress.get("level", 1))
	var total_xp: int = int(progress.get("xp", 0))
	var into_lvl: int = Leveling.xp_into_current_level(total_xp, lvl)
	var to_next: int = Leveling.xp_to_next_level(lvl)
	var gold: int = SaveManager.get_currency("gold")

	# Header row: Level + XP bar
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	v.add_child(header)

	var lvl_label := Label.new()
	lvl_label.text = "Lv %d" % lvl
	lvl_label.add_theme_font_size_override("font_size", 18)
	lvl_label.add_theme_color_override("font_color", Color(0.976, 0.78, 0.31, 1))
	header.add_child(lvl_label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 14)
	bar.max_value = float(to_next)
	bar.value = float(into_lvl)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.78, 0.42, 1)
	bar.add_theme_stylebox_override("fill", fill)
	header.add_child(bar)

	var xp_label := Label.new()
	xp_label.text = "%d / %d" % [into_lvl, to_next]
	xp_label.add_theme_font_size_override("font_size", 12)
	xp_label.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 1))
	header.add_child(xp_label)

	# Gold-on-hand readout (the level-up rows reference this)
	var gold_label := Label.new()
	gold_label.text = "Gold: %d" % gold
	gold_label.add_theme_font_size_override("font_size", 12)
	gold_label.add_theme_color_override("font_color", Color(0.976, 0.78, 0.31, 1))
	v.add_child(gold_label)

	# One row per potion type — "Use" button consumes 1 + gold cost,
	# then refreshes the panel.
	for item_id in Items.DISPLAY_ORDER:
		v.add_child(_build_potion_row(item_id, gold))

	return panel


func _build_potion_row(item_id: String, gold_on_hand: int) -> Control:
	var item: Dictionary = Items.ITEMS[item_id]
	var owned: int = SaveManager.get_item(item_id)
	var cost: int = int(item["gold_cost"])
	var xp_value: int = int(item["xp"])

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var name_lbl := Label.new()
	name_lbl.text = "%s (+%d XP)" % [item["name"], xp_value]
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override("font_color", Color(0.957, 0.957, 0.957, 1))
	name_lbl.custom_minimum_size = Vector2(190, 0)
	row.add_child(name_lbl)

	var owned_lbl := Label.new()
	owned_lbl.text = "x%d" % owned
	owned_lbl.add_theme_font_size_override("font_size", 13)
	owned_lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85, 1))
	owned_lbl.custom_minimum_size = Vector2(40, 0)
	row.add_child(owned_lbl)

	var cost_lbl := Label.new()
	cost_lbl.text = "%d gold" % cost
	cost_lbl.add_theme_font_size_override("font_size", 13)
	cost_lbl.add_theme_color_override("font_color", Color(0.976, 0.78, 0.31, 1))
	cost_lbl.custom_minimum_size = Vector2(70, 0)
	row.add_child(cost_lbl)

	var btn := Button.new()
	btn.text = "Use"
	btn.custom_minimum_size = Vector2(60, 0)
	# Disable if we can't afford it — either no potions or not enough gold.
	btn.disabled = owned <= 0 or gold_on_hand < cost
	btn.pressed.connect(_on_use_potion.bind(item_id))
	row.add_child(btn)

	return row


## Spend one of `item_id` (and its gold cost) to add XP to the current
## hero. SaveManager handles the level recompute + persist; we just
## rebuild the panel to reflect the new state.
func _on_use_potion(item_id: String) -> void:
	if _current_hero == null:
		return
	var item: Dictionary = Items.ITEMS[item_id]
	var cost: int = int(item["gold_cost"])
	if SaveManager.get_currency("gold") < cost:
		return
	if not SaveManager.consume_item(item_id, 1):
		return
	SaveManager.add_currency("gold", -cost)
	var result: Dictionary = SaveManager.add_hero_xp(_current_hero.id, int(item["xp"]))
	if result.leveled_up:
		print("[Detail] %s leveled up: %d -> %d" % [
			_current_hero.id, result.old_level, result.new_level,
		])
		# Stats live on HeroData base values + level multiplier — they
		# re-compute every battle from current level, so no extra refresh
		# needed here. The displayed base stats stay the same.
	_rebuild_progression_panel()
