extends PanelContainer
## Visual badge for one active status on a unit.
##
## Phase 2a placeholder: colored box with a letter + a small turns-remaining
## label. Phase 2b+ swaps the letter for a real pixel-art icon and adds
## flair (subtle pulse, tinted by element).

@onready var _letter: Label = $V/Letter
@onready var _turns: Label = $V/Turns

var _bg_style: StyleBoxFlat


func _ready() -> void:
	_bg_style = StyleBoxFlat.new()
	_bg_style.border_color = Color(0, 0, 0, 0.8)
	_bg_style.border_width_left = 1
	_bg_style.border_width_top = 1
	_bg_style.border_width_right = 1
	_bg_style.border_width_bottom = 1
	_bg_style.corner_radius_top_left = 2
	_bg_style.corner_radius_top_right = 2
	_bg_style.corner_radius_bottom_left = 2
	_bg_style.corner_radius_bottom_right = 2
	add_theme_stylebox_override("panel", _bg_style)


func bind(data: StatusEffectData, turns: int) -> void:
	_bg_style.bg_color = data.icon_color
	_letter.text = data.icon_letter
	_turns.text = str(turns)
	tooltip_text = "%s — %d turn%s" % [data.display_name, turns, "" if turns == 1 else "s"]


func set_turns(turns: int) -> void:
	_turns.text = str(turns)
	tooltip_text = tooltip_text.split(" — ")[0] + " — %d turn%s" % [turns, "" if turns == 1 else "s"]
