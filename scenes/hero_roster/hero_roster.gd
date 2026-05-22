extends Control
## Phase 3a — Hero Roster: grid of every hero in ContentRegistry.
##
## Each card is built procedurally (Polygon2D sprite-color preview + name +
## element/class chip). Clicking a card stashes the hero id on Game and
## transitions to the Hero Detail scene.

const ELEMENT_NAMES := ["FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK"]
const CLASS_NAMES := ["ATTACKER", "DEFENDER", "HEALER", "BUFFER", "DEBUFFER", "RANGER"]

const ELEMENT_COLORS := [
	Color(0.97, 0.55, 0.22, 1),   # Fire — orange
	Color(0.27, 0.55, 0.88, 1),   # Water — blue
	Color(0.36, 0.70, 0.42, 1),   # Earth — green
	Color(0.78, 0.88, 0.96, 1),   # Wind — pale cyan
	Color(0.99, 0.83, 0.26, 1),   # Light — gold
	Color(0.48, 0.30, 0.73, 1),   # Dark — purple
]

@onready var _grid: GridContainer = $Scroll/VBox/Grid
@onready var _empty_label: Label = $Scroll/VBox/EmptyLabel


func _ready() -> void:
	Game.transition_state(Game.State.ROSTER)
	_populate()


func _populate() -> void:
	# Clear existing cards
	for child in _grid.get_children():
		child.queue_free()

	var ids: Array = ContentRegistry.heroes.keys()
	ids.sort()
	if ids.is_empty():
		_empty_label.visible = true
		return
	_empty_label.visible = false

	for id in ids:
		var hero: HeroData = ContentRegistry.get_hero(id)
		if hero == null: continue
		var card := _make_card(hero)
		_grid.add_child(card)


func _make_card(hero: HeroData) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(230, 280)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.107, 0.107, 0.16, 1)
	sb.border_color = Color(0.337, 0.424, 0.525, 1)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	card.add_theme_stylebox_override("panel", sb)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)

	# Sprite color preview (a ColorRect — placeholder; real portraits in Phase 3+)
	var sprite_box := ColorRect.new()
	sprite_box.custom_minimum_size = Vector2(120, 160)
	sprite_box.color = hero.sprite_color
	sprite_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(sprite_box)

	# Name
	var name_label := Label.new()
	name_label.text = hero.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.957, 0.957, 0.957, 1))
	v.add_child(name_label)

	# Element + class chip
	var chips := HBoxContainer.new()
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	chips.add_theme_constant_override("separation", 6)
	v.add_child(chips)

	var element_chip := _make_chip(
		ELEMENT_NAMES[hero.element] if hero.element >= 0 and hero.element < ELEMENT_NAMES.size() else "?",
		ELEMENT_COLORS[hero.element] if hero.element >= 0 and hero.element < ELEMENT_COLORS.size() else Color.GRAY,
	)
	chips.add_child(element_chip)

	var class_chip := _make_chip(
		CLASS_NAMES[hero.class_type] if hero.class_type >= 0 and hero.class_type < CLASS_NAMES.size() else "?",
		Color(0.337, 0.424, 0.525, 1),
	)
	chips.add_child(class_chip)

	# Make the whole card clickable
	card.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_open_detail(hero.id)
	)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return card


func _make_chip(text: String, color: Color) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_left = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 11)
	l.add_theme_color_override("font_color", Color.WHITE)
	p.add_child(l)
	return p


func _open_detail(hero_id: String) -> void:
	Game.current_detail_hero_id = hero_id
	Game.change_scene("res://scenes/hero_detail/hero_detail.tscn")


func _on_back_pressed() -> void:
	Game.change_scene("res://scenes/hub/hub.tscn")
