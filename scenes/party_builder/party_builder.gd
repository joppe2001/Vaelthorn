extends Control
## Phase 3b — Party Builder.
##
## Top: three slot cards reflecting Game.selected_party_ids (in order).
## Bottom: a pool of all heroes from ContentRegistry. Click a pool card to
## drop them into the first empty slot. Click a filled slot card to remove
## them back to the pool. "Start Battle" enabled only when all 3 slots are
## filled.

const ELEMENT_NAMES := ["FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK"]
const CLASS_NAMES := ["ATTACKER", "DEFENDER", "HEALER", "BUFFER", "DEBUFFER", "RANGER"]

@onready var _slots_hbox: HBoxContainer = $Layout/SlotsRow
@onready var _pool_grid: GridContainer = $Layout/PoolScroll/VBox/PoolGrid
@onready var _start_btn: Button = $StartBtn

var _slots: Array[String] = []  # 3 entries, "" for empty


func _ready() -> void:
	Game.transition_state(Game.State.PARTY_BUILDER)
	# Initialize from the current selection — keep what the user had.
	_slots.resize(Game.PARTY_SIZE)
	for i in Game.PARTY_SIZE:
		if i < Game.selected_party_ids.size():
			_slots[i] = String(Game.selected_party_ids[i])
		else:
			_slots[i] = ""
	_refresh()


func _refresh() -> void:
	_refresh_slots()
	_refresh_pool()
	_refresh_start_button()


func _refresh_slots() -> void:
	for child in _slots_hbox.get_children():
		child.queue_free()
	for i in Game.PARTY_SIZE:
		var hero_id := _slots[i]
		var slot := _make_slot_card(i, hero_id)
		_slots_hbox.add_child(slot)


func _make_slot_card(slot_idx: int, hero_id: String) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 240)
	var sb := StyleBoxFlat.new()
	if hero_id == "":
		sb.bg_color = Color(0.082, 0.082, 0.137, 1)
		sb.border_color = Color(0.337, 0.424, 0.525, 0.7)
	else:
		sb.bg_color = Color(0.107, 0.107, 0.16, 1)
		sb.border_color = Color(0.976, 0.78, 0.31, 1)
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
	v.add_theme_constant_override("separation", 8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	var slot_label := Label.new()
	slot_label.text = "SLOT %d" % (slot_idx + 1)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.add_theme_font_size_override("font_size", 11)
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.78, 1))
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(slot_label)

	if hero_id == "":
		var empty_label := Label.new()
		empty_label.text = "+ empty"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.62, 1))
		empty_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(empty_label)
	else:
		var hero: HeroData = ContentRegistry.get_hero(hero_id)
		if hero != null:
			v.add_child(_make_portrait_view(hero, Vector2(140, 140)))
			var name_label := Label.new()
			name_label.text = hero.display_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_label.add_theme_font_size_override("font_size", 14)
			name_label.add_theme_color_override("font_color", Color(0.957, 0.957, 0.957, 1))
			name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(name_label)
			var remove_hint := Label.new()
			remove_hint.text = "click to remove"
			remove_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			remove_hint.add_theme_font_size_override("font_size", 10)
			remove_hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.62, 1))
			remove_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(remove_hint)
		# Clicking a filled slot removes
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_remove_from_slot(slot_idx)
		)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return card


## Portrait helper — returns TextureRect when the hero has art, ColorRect
## fallback otherwise. mouse_filter=IGNORE so clicks bubble to the card.
func _make_portrait_view(hero: HeroData, size: Vector2) -> Control:
	if hero.portrait != null:
		var tex := TextureRect.new()
		tex.texture = hero.portrait
		tex.custom_minimum_size = size
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return tex
	var rect := ColorRect.new()
	rect.custom_minimum_size = size
	rect.color = hero.sprite_color
	rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _refresh_pool() -> void:
	for child in _pool_grid.get_children():
		child.queue_free()
	var ids: Array = ContentRegistry.heroes.keys()
	ids.sort()
	for id in ids:
		var hero: HeroData = ContentRegistry.get_hero(id)
		if hero == null: continue
		_pool_grid.add_child(_make_pool_card(hero))


func _make_pool_card(hero: HeroData) -> Control:
	var already_picked: bool = _slots.has(hero.id)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(180, 200)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.107, 0.107, 0.16, 0.5 if already_picked else 1.0)
	sb.border_color = Color(0.337, 0.424, 0.525, 0.4 if already_picked else 1.0)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	card.add_theme_stylebox_override("panel", sb)
	if already_picked:
		card.modulate = Color(0.55, 0.55, 0.55, 1)

	var v := VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(v)

	v.add_child(_make_portrait_view(hero, Vector2(120, 120)))

	var name_label := Label.new()
	name_label.text = hero.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.957, 0.957, 0.957, 1))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(name_label)

	var chip := Label.new()
	var elem: String = ELEMENT_NAMES[hero.element] if hero.element >= 0 and hero.element < ELEMENT_NAMES.size() else "?"
	var cls: String = CLASS_NAMES[hero.class_type] if hero.class_type >= 0 and hero.class_type < CLASS_NAMES.size() else "?"
	chip.text = "%s • %s" % [elem, cls]
	chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_theme_font_size_override("font_size", 10)
	chip.add_theme_color_override("font_color", Color(0.6, 0.7, 0.78, 1))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(chip)

	# Clicking adds to first empty slot (if not already picked)
	if not already_picked:
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_add_to_first_empty(hero.id)
		)
	return card


func _refresh_start_button() -> void:
	var full := true
	for s in _slots:
		if s == "":
			full = false; break
	_start_btn.disabled = not full


func _add_to_first_empty(hero_id: String) -> void:
	for i in Game.PARTY_SIZE:
		if _slots[i] == "":
			_slots[i] = hero_id
			_refresh()
			return


func _remove_from_slot(idx: int) -> void:
	if idx < 0 or idx >= Game.PARTY_SIZE: return
	_slots[idx] = ""
	_refresh()


func _on_start_pressed() -> void:
	# set_party_ids persists the choice through SaveManager so it's
	# remembered across runs.
	Game.set_party_ids(PackedStringArray(_slots))
	Game.change_scene("res://scenes/battle/battle.tscn")


func _on_back_pressed() -> void:
	Game.change_scene("res://scenes/hub/hub.tscn")
