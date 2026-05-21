extends Node2D
## Visual representation of a combatant in the battle scene.
##
## Phase 1: placeholder rectangle + name + HP bar. Phase 2+ swaps the
## Polygon2D for SpriteFrames animations (idle/attack/hurt/ult).

@onready var _sprite: Polygon2D = $Sprite
@onready var _name_label: Label = $UIRoot/NameLabel
@onready var _hp_bar: ProgressBar = $UIRoot/HPBar
@onready var _hp_label: Label = $UIRoot/HPLabel

var _base_color: Color = Color.WHITE


func bind(unit_name: String, color: Color, max_hp: int) -> void:
	_name_label.text = unit_name
	_sprite.color = color
	_base_color = color
	_hp_bar.max_value = max_hp
	_hp_bar.value = max_hp
	_hp_label.text = "%d / %d" % [max_hp, max_hp]


func set_hp(current: int, max_hp: int) -> void:
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [current, max_hp]
	# Hit flash + small nudge
	var tween := create_tween()
	tween.tween_property(_sprite, "color", Color(1.4, 1.4, 1.4, 1.0), 0.05)
	tween.tween_property(_sprite, "color", _base_color, 0.18)
	var bump := create_tween()
	bump.tween_property(self, "position:x", position.x + 6, 0.06)
	bump.tween_property(self, "position:x", position.x, 0.10)
