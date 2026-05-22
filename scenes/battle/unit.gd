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

# Created programmatically in _ensure_ultimate_gauge() so it survives Godot's
# .tscn autosaves while the scene is open in the editor.
var _ultimate_gauge: ProgressBar
@onready var _target_marker: Polygon2D = $TargetMarker
@onready var _active_marker: Polygon2D = $ActiveMarker
@onready var _click_area: Area2D = $ClickArea

var _base_color: Color = Color.WHITE
var _t: float = 0.0
var _marker_t: float = 0.0
var _using_anim_sprite: bool = false
var _icons_by_status: Dictionary = {}
var _is_dead: bool = false
var _is_selected: bool = false

var statuses: StatusManager = StatusManager.new()
var _ultimate_value: float = 0.0


# ─── Ultimate gauge ──────────────────────────────────────────────────

func add_ultimate(amount: float) -> void:
	set_ultimate(_ultimate_value + amount)


func set_ultimate(value: float) -> void:
	_ultimate_value = clamp(value, 0.0, 100.0)
	if _ultimate_gauge:
		_ultimate_gauge.value = _ultimate_value


func reset_ultimate() -> void:
	set_ultimate(0.0)


func is_ultimate_ready() -> bool:
	return _ultimate_value >= 100.0


## Hide the gauge bar entirely. Used for enemies (they don't have ultimates).
func set_ultimate_visible(is_visible: bool) -> void:
	if _ultimate_gauge:
		_ultimate_gauge.visible = is_visible


func _ready() -> void:
	_t = randf() * TAU
	_click_area.input_event.connect(_on_click_area_input)
	_ensure_ultimate_gauge()
	# Auto-return to idle after non-looping animations (attack, hurt, etc.)
	if _anim_sprite:
		_anim_sprite.animation_finished.connect(_on_anim_finished)


func _on_anim_finished() -> void:
	# Only return to idle if we're alive and the current anim isn't idle.
	if _is_dead: return
	if _anim_sprite == null or _anim_sprite.sprite_frames == null: return
	if _anim_sprite.animation == &"idle": return
	if _anim_sprite.sprite_frames.has_animation(&"idle"):
		_anim_sprite.play(&"idle")


## Play the attack swing animation. Non-blocking — animation_finished
## brings the sprite back to idle automatically.
## No-op (briefly stalls) for units without an AnimatedSprite2D.
func play_attack() -> void:
	if not _using_anim_sprite: return
	if _anim_sprite == null or _anim_sprite.sprite_frames == null: return
	if not _anim_sprite.sprite_frames.has_animation(&"attack"): return
	_anim_sprite.play(&"attack")


## Play the hurt recoil frame when this unit takes damage. Same pattern as
## play_attack — non-blocking, returns to idle via animation_finished.
func play_hurt() -> void:
	if _is_dead: return
	if not _using_anim_sprite: return
	if _anim_sprite == null or _anim_sprite.sprite_frames == null: return
	if not _anim_sprite.sprite_frames.has_animation(&"hurt"): return
	_anim_sprite.play(&"hurt")


func _ensure_ultimate_gauge() -> void:
	var root: Control = $UIRoot
	if root.has_node("UltimateGauge"):
		_ultimate_gauge = root.get_node("UltimateGauge")
		return
	var bar := ProgressBar.new()
	bar.name = "UltimateGauge"
	bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bar.offset_left = 52
	bar.offset_top = 82
	bar.offset_right = 188
	bar.offset_bottom = 90
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.07, 0.07, 0.12, 1)
	bg_style.border_color = Color(0.3, 0.3, 0.4, 1)
	bg_style.border_width_left = 1
	bg_style.border_width_top = 1
	bg_style.border_width_right = 1
	bg_style.border_width_bottom = 1
	bar.add_theme_stylebox_override("background", bg_style)

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.976, 0.78, 0.31, 1)
	bar.add_theme_stylebox_override("fill", fill_style)

	root.add_child(bar)
	_ultimate_gauge = bar


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


## Show the cyan underline marker — used to indicate WHOSE turn it is right
## now (the active actor). Distinct from set_selected (gold chevron = the
## player's chosen attack target).
func set_active(active: bool) -> void:
	_active_marker.visible = active and not _is_dead


func set_dead(is_dead: bool) -> void:
	_is_dead = is_dead
	if is_dead:
		_target_marker.visible = false
		_active_marker.visible = false
		set_targetable(false)
		# Play the lying-down dead frame if the unit has one (heroes do, slimes don't)
		if _using_anim_sprite and _anim_sprite != null and _anim_sprite.sprite_frames != null and _anim_sprite.sprite_frames.has_animation(&"dead"):
			_anim_sprite.play(&"dead")
		var fade := create_tween()
		fade.set_parallel(true)
		if _using_anim_sprite:
			fade.tween_property(_anim_sprite, "modulate:a", 0.45, 0.6)
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
