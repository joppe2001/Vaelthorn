extends Node2D
## Visual representation of one combatant.
##
## Phase 2d additions:
##   - clicked signal (Area2D-based hit detection) for targeting UI
##   - set_selected() toggles the gold chevron marker above the unit
##   - set_dead() fades the sprite + disables clicks when HP hits 0
##
## SpriteHolder hosts both the Polygon2D placeholder and the AnimatedSprite2D
## (real art). bind() picks which to show via the optional idle_frames arg.

signal clicked(unit: Node2D)

const STATUS_ICON_SCENE := preload("res://scenes/battle/status_icon.tscn")

@onready var _sprite_holder: Node2D = $SpriteHolder
@onready var _sprite: Polygon2D = $SpriteHolder/Sprite
@onready var _anim_sprite: AnimatedSprite2D = $SpriteHolder/AnimatedSprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _name_label: Label = $UIRoot/NameLabel
@onready var _hp_bar: ProgressBar = $UIRoot/HPBar
@onready var _hp_label: Label = $UIRoot/HPLabel
@onready var _status_row: HBoxContainer = $UIRoot/StatusRow
@onready var _target_marker: Polygon2D = $TargetMarker
@onready var _click_area: Area2D = $ClickArea

var _base_color: Color = Color.WHITE
var _t: float = 0.0
var _marker_t: float = 0.0
var _using_anim_sprite: bool = false
var _icons_by_status: Dictionary = {}
var _is_dead: bool = false
var _is_selected: bool = false

var statuses: StatusManager = StatusManager.new()


func _ready() -> void:
	_t = randf() * TAU
	_click_area.input_event.connect(_on_click_area_input)


func _process(delta: float) -> void:
	# Idle bob
	_t += delta * 2.4
	_sprite_holder.position.y = sin(_t) * 3.0
	# Subtle pulse on the target marker so it's eye-catching
	if _is_selected:
		_marker_t += delta * 5.0
		var pulse: float = 0.85 + sin(_marker_t) * 0.15
		_target_marker.modulate.a = pulse


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


# ─── Targeting + death ───────────────────────────────────────────────

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_target_marker.visible = selected and not _is_dead
	if selected:
		_target_marker.modulate = Color(1, 1, 1, 1)
		_marker_t = 0.0


func set_targetable(can_target: bool) -> void:
	# Toggle the Area2D pickability — dead enemies stop receiving clicks.
	_click_area.input_pickable = can_target


func set_dead(is_dead: bool) -> void:
	_is_dead = is_dead
	if is_dead:
		_target_marker.visible = false
		set_targetable(false)
		var fade := create_tween()
		fade.set_parallel(true)
		if _using_anim_sprite:
			fade.tween_property(_anim_sprite, "modulate:a", 0.35, 0.4)
		else:
			fade.tween_property(_sprite, "color:a", 0.35, 0.4)
		fade.tween_property(_shadow, "modulate:a", 0.15, 0.4)
	else:
		set_targetable(true)


func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_dead: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[Unit] click on %s" % _name_label.text)
		clicked.emit(self)


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
	for sid in _icons_by_status.keys():
		if not statuses.has(sid):
			_icons_by_status[sid].queue_free()
			_icons_by_status.erase(sid)
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
