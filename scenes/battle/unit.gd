extends Node2D
## Visual representation of a combatant in the battle scene.
##
## Phase 2a:
##   - Hosts a per-unit StatusManager (active Burn/Stun/buffs/debuffs).
##   - Renders status icons in a row above the name label.
##   - Damage flash + scale punch + position bump still work on either
##     Polygon2D (placeholder enemies) or AnimatedSprite2D (real sprites).

const STATUS_ICON_SCENE := preload("res://scenes/battle/status_icon.tscn")

@onready var _sprite_holder: Node2D = $SpriteHolder
@onready var _sprite: Polygon2D = $SpriteHolder/Sprite
@onready var _anim_sprite: AnimatedSprite2D = $SpriteHolder/AnimatedSprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _name_label: Label = $UIRoot/NameLabel
@onready var _hp_bar: ProgressBar = $UIRoot/HPBar
@onready var _hp_label: Label = $UIRoot/HPLabel
@onready var _status_row: HBoxContainer = $UIRoot/StatusRow

var _base_color: Color = Color.WHITE
var _t: float = 0.0
var _using_anim_sprite: bool = false
var _icons_by_status: Dictionary = {}   ## status_id -> StatusIcon node

## StatusManager owned by this unit. Battle scene reads/mutates via the
## helper methods below.
var statuses: StatusManager = StatusManager.new()


func _ready() -> void:
	_t = randf() * TAU


func _process(delta: float) -> void:
	# Gentle idle bob — sin wave, 3-pixel amplitude
	_t += delta * 2.4
	_sprite_holder.position.y = sin(_t) * 3.0


func bind(unit_name: String, color: Color, max_hp: int, idle_frames: SpriteFrames = null, sprite_scale: float = 4.0, sprite_y_offset: float = -96.0) -> void:
	_name_label.text = unit_name

	if idle_frames != null:
		_using_anim_sprite = true
		_sprite.visible = false
		_anim_sprite.visible = true
		_anim_sprite.sprite_frames = idle_frames
		_anim_sprite.scale = Vector2(sprite_scale, sprite_scale)
		_anim_sprite.position = Vector2(0, sprite_y_offset)
		if idle_frames.has_animation(&"idle"):
			_anim_sprite.animation = &"idle"
			_anim_sprite.play()
	else:
		_using_anim_sprite = false
		_sprite.visible = true
		_anim_sprite.visible = false
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

	var flash := create_tween()
	if _using_anim_sprite:
		flash.tween_property(_anim_sprite, "modulate", Color(1.6, 1.6, 1.6, 1.0), 0.04)
		flash.tween_property(_anim_sprite, "modulate", Color.WHITE, 0.18)
	else:
		flash.tween_property(_sprite, "color", Color(1.4, 1.4, 1.4, 1.0), 0.04)
		flash.tween_property(_sprite, "color", _base_color, 0.18)

	var punch := create_tween()
	punch.tween_property(_sprite_holder, "scale", Vector2(1.06, 0.94), 0.06)
	punch.tween_property(_sprite_holder, "scale", Vector2(1.0, 1.0), 0.12)

	var bump := create_tween()
	bump.tween_property(self, "position:x", position.x + 8, 0.06)
	bump.tween_property(self, "position:x", position.x, 0.10)


# ─── Status icon management ──────────────────────────────────────────

func add_status(status_id: String, duration: int, power: float, data: StatusEffectData) -> void:
	statuses.add(status_id, duration, power, data)
	_refresh_status_icons()


func remove_status(status_id: String) -> void:
	statuses.remove(status_id)
	_refresh_status_icons()


func refresh_status_durations() -> void:
	_refresh_status_icons()


func _refresh_status_icons() -> void:
	# Remove icons for statuses no longer active
	for sid in _icons_by_status.keys():
		if not statuses.has(sid):
			_icons_by_status[sid].queue_free()
			_icons_by_status.erase(sid)
	# Add or update icons for active statuses
	for sid in statuses.all_ids():
		var entry = statuses.active[sid]
		if _icons_by_status.has(sid):
			_icons_by_status[sid].set_turns(entry.remaining_turns)
		else:
			var icon := STATUS_ICON_SCENE.instantiate()
			_status_row.add_child(icon)
			icon.bind(entry.data, entry.remaining_turns)
			_icons_by_status[sid] = icon


func _update_hp_color(current: int, max_hp: int) -> void:
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
