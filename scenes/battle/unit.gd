extends Node2D
## Visual representation of a combatant in the battle scene.
##
## Phase 1.5: bigger sprite, idle bob, ground shadow, styled HP bar.
## Phase 2+: SpriteHolder will host AnimatedSprite2D (Mana Seed frames)
## instead of the placeholder Polygon2D.

@onready var _sprite_holder: Node2D = $SpriteHolder
@onready var _sprite: Polygon2D = $SpriteHolder/Sprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _name_label: Label = $UIRoot/NameLabel
@onready var _hp_bar: ProgressBar = $UIRoot/HPBar
@onready var _hp_label: Label = $UIRoot/HPLabel

var _base_color: Color = Color.WHITE
var _t: float = 0.0
var _bob_offset: float = 0.0


func _ready() -> void:
	# Slightly random phase so player + enemy don't bob in lockstep
	_t = randf() * TAU


func _process(delta: float) -> void:
	# Gentle idle bob — sin wave, 3-pixel amplitude, ~2s period.
	_t += delta * 2.4
	var bob: float = sin(_t) * 3.0
	_sprite_holder.position.y = bob
	_bob_offset = bob


func bind(unit_name: String, color: Color, max_hp: int) -> void:
	_name_label.text = unit_name
	_sprite.color = color
	_base_color = color
	_hp_bar.max_value = max_hp
	_hp_bar.value = max_hp
	_hp_label.text = "%d / %d" % [max_hp, max_hp]
	_update_hp_color(max_hp, max_hp)


func set_hp(current: int, max_hp: int) -> void:
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [current, max_hp]
	_update_hp_color(current, max_hp)

	# Hit flash on the sprite color
	var flash := create_tween()
	flash.tween_property(_sprite, "color", Color(1.4, 1.4, 1.4, 1.0), 0.04)
	flash.tween_property(_sprite, "color", _base_color, 0.18)

	# Scale punch on the sprite holder
	var punch := create_tween()
	punch.tween_property(_sprite_holder, "scale", Vector2(1.06, 0.94), 0.06)
	punch.tween_property(_sprite_holder, "scale", Vector2(1.0, 1.0), 0.12)

	# Position bump on the unit root
	var bump := create_tween()
	bump.tween_property(self, "position:x", position.x + 8, 0.06)
	bump.tween_property(self, "position:x", position.x, 0.10)


func _update_hp_color(current: int, max_hp: int) -> void:
	# Swap to a desaturated red when HP drops below 25%.
	var ratio: float = float(current) / float(max(max_hp, 1))
	var fill_style: StyleBoxFlat = _hp_bar.get("theme_override_styles/fill")
	if fill_style == null:
		return
	if ratio <= 0.25:
		fill_style.bg_color = Color(0.478, 0.122, 0.145, 1)
	elif ratio <= 0.5:
		fill_style.bg_color = Color(0.937, 0.604, 0.227, 1)
	else:
		fill_style.bg_color = Color(0.796, 0.255, 0.294, 1)
