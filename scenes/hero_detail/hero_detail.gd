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
@onready var _portrait: ColorRect = $Layout/Portrait
@onready var _sub_label: Label = $Layout/Right/SubLabel
@onready var _stats_grid: GridContainer = $Layout/Right/StatsGrid
@onready var _skills_vbox: VBoxContainer = $Layout/Right/SkillsScroll/SkillsVBox
@onready var _lore_label: Label = $Lore


func _ready() -> void:
	Game.transition_state(Game.State.DETAIL)
	var hero: HeroData = ContentRegistry.get_hero(Game.current_detail_hero_id)
	if hero == null:
		_heading.text = "Hero not found"
		return
	_populate(hero)


func _populate(hero: HeroData) -> void:
	_heading.text = hero.display_name
	_portrait.color = hero.sprite_color

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
