extends HBoxContainer
## Shows the next N actors in the ATB queue.
##
## Each chip is a colored panel with a single letter (first letter of the
## unit's display name) — placeholder until Phase 3 swaps in portraits.

const CHIP_COUNT := 5
const CHIP_SIZE := Vector2(36, 36)

var _chips: Array[PanelContainer] = []
var _unit_color: Dictionary = {}    ## unit_id -> Color
var _unit_letter: Dictionary = {}   ## unit_id -> String


func _ready() -> void:
	for i in CHIP_COUNT:
		var chip := _make_chip()
		add_child(chip)
		_chips.append(chip)


func register_unit(unit_id: String, color: Color, display_name: String) -> void:
	_unit_color[unit_id] = color
	_unit_letter[unit_id] = display_name.substr(0, 1).to_upper()


## Update the UI to reflect a predicted sequence of actor ids.
func set_sequence(actor_ids: Array) -> void:
	for i in CHIP_COUNT:
		var chip := _chips[i]
		if i < actor_ids.size():
			var id: String = actor_ids[i]
			chip.visible = true
			_paint_chip(chip, _unit_color.get(id, Color.WHITE), _unit_letter.get(id, "?"))
		else:
			chip.visible = false


func _make_chip() -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = CHIP_SIZE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.4, 0.4, 0.4, 1)
	sb.border_color = Color(0, 0, 0, 0.6)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.corner_radius_top_left = 3
	sb.corner_radius_top_right = 3
	sb.corner_radius_bottom_right = 3
	sb.corner_radius_bottom_left = 3
	p.add_theme_stylebox_override("panel", sb)

	var l := Label.new()
	l.text = "?"
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", Color.WHITE)
	p.add_child(l)

	return p


func _paint_chip(chip: PanelContainer, color: Color, letter: String) -> void:
	var sb: StyleBoxFlat = chip.get_theme_stylebox("panel")
	if sb != null:
		sb.bg_color = color
	var l := chip.get_child(0) as Label
	if l != null:
		l.text = letter
