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
const BURN_AMBIENT_SCENE := preload("res://scenes/battle/burn_ambient.tscn")
const DEATH_EFFECT_SCENE := preload("res://scenes/battle/death_effect.tscn")

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

# Live burn ambient sprite while this unit has the burn status. Kept as
# a child so it follows the unit through dashes and position bumps.
var _burn_ambient: Node2D = null

var statuses: StatusManager = StatusManager.new()
var _ultimate_value: float = 0.0

# Cached character bounds in unit-local coordinates. Populated by bind()
# by scanning the alpha channel of the first idle frame — so the anchors
# track the actual character pixels, not the bounding frame (which may
# include empty padding above the head or below the feet).
#
#   _char_top_y    — y of the topmost opaque pixel (head/hair tip)
#   _char_bottom_y — y of the bottommost opaque pixel (feet)
#   _char_height   — total visible character height
var _char_top_y: float = -200.0
var _char_bottom_y: float = 0.0
var _char_height: float = 200.0


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


## Play a one-shot body animation, then auto-return to idle via the
## animation_finished hook. Non-blocking.
##
## Currently shipped variants:
##   "attack" — slash 1 (default for offensive skills)
##   "slash2" — wider/heavier swing
##   "thrust" — forward jab
##   "brace"  — east-facing crouch w/ shield up (Brace / Aegis)
##   "cast"   — upright guard pose (Mend channel)
##
## Empty StringName => no-op (caller signalled "no body anim for this skill").
## A missing offensive variant (slash2/thrust) falls back to "attack" so a
## broken data wire still reads as a hit. Defensive poses (brace/cast) just
## no-op when missing — we never want a heal silently becoming a slash.
## No-op for units without an AnimatedSprite2D (slimes/goblins).
func play_attack(variant: StringName = &"attack") -> void:
	if variant == &"": return
	if not _using_anim_sprite: return
	if _anim_sprite == null or _anim_sprite.sprite_frames == null: return
	var anim: StringName = variant
	if not _anim_sprite.sprite_frames.has_animation(anim):
		if variant in [&"slash2", &"thrust"]:
			anim = &"attack"
		else:
			return
	if not _anim_sprite.sprite_frames.has_animation(anim):
		return
	_anim_sprite.play(anim)


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
	# Idle bob — only for placeholder Polygon2D units, since real
	# AnimatedSprite2D characters already have breathing built into
	# their idle animation. Adding a script bob on top makes the
	# heroes look like they're floating.
	if not _using_anim_sprite:
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
		if idle_frames.has_animation(&"idle"):
			_anim_sprite.animation = &"idle"
			_anim_sprite.play()
		# Auto-ground: scan the idle frame to find where the feet sit in
		# the sprite, and choose a y_offset that puts those feet at y=0
		# (the shadow line). Falls back to the hand-tuned offset if the
		# image can't be read. This means new sprites just need a scale
		# value — they ground themselves automatically.
		var final_offset: float = _compute_grounded_y_offset(idle_frames, sprite_scale)
		if is_nan(final_offset):
			final_offset = sprite_y_offset
		_anim_sprite.position = Vector2(0, final_offset)
		# Now measure character bounds in unit-local using the final offset.
		_measure_character_bounds(idle_frames, sprite_scale, final_offset)
	else:
		_using_anim_sprite = false
		_sprite.visible = true
		_anim_sprite.visible = false
		_sprite.color = color
		_base_color = color
		# Placeholder polygon — use a roughly hero-sized default so popups
		# don't collide with the placeholder square.
		_char_top_y = -180.0
		_char_bottom_y = 0.0
		_char_height = 180.0

	_hp_bar.max_value = max_hp
	_hp_bar.value = max_hp
	_hp_label.text = "%d / %d" % [max_hp, max_hp]
	_update_hp_color(max_hp, max_hp)


## Find the y_offset that puts the character's feet at y=0 (shadow
## line). Done by alpha-scanning the first idle frame — bounds.position.y
## + bounds.size.y is the lowest opaque pixel (feet). To put those feet
## at y=0:
##
##   feet_in_frame  = bounds.bottom (px from frame top)
##   feet_below_ctr = feet_in_frame - frame_h/2
##   needed_offset  = -feet_below_ctr * sprite_scale
##
## Returns NAN if the image can't be read; caller falls back to the
## hand-tuned sprite_y_offset.
func _compute_grounded_y_offset(frames: SpriteFrames, sprite_scale: float) -> float:
	if not frames.has_animation(&"idle"):
		return NAN
	if frames.get_frame_count(&"idle") <= 0:
		return NAN
	var tex: Texture2D = frames.get_frame_texture(&"idle", 0)
	if tex == null:
		return NAN
	var frame_image: Image
	if tex is AtlasTexture:
		var atlas_tex: AtlasTexture = tex
		if atlas_tex.atlas == null:
			return NAN
		var atlas_image: Image = atlas_tex.atlas.get_image()
		if atlas_image == null:
			return NAN
		frame_image = atlas_image.get_region(atlas_tex.region)
	else:
		frame_image = tex.get_image()
	if frame_image == null:
		return NAN
	var bounds: Rect2i = frame_image.get_used_rect()
	if bounds.size.y <= 0:
		return NAN
	var frame_h: float = float(frame_image.get_height())
	var feet_in_frame: float = float(bounds.position.y + bounds.size.y)
	var feet_below_center: float = feet_in_frame - frame_h * 0.5
	return -feet_below_center * sprite_scale


## Scan the alpha channel of the first idle frame to find the actual
## character bounds (top opaque pixel to bottom opaque pixel). Cached
## results feed get_anchor(), so anchors latch onto the real character
## body — ignoring any empty padding above the head or below the feet
## that the sprite cell happens to include.
##
## Works for AtlasTexture (Mana Seed sheets) and plain Texture2D
## (0x72 single-frame PNGs). Falls back to safe defaults if the image
## can't be read (compressed import, missing texture, etc).
func _measure_character_bounds(frames: SpriteFrames, sprite_scale: float, sprite_y_offset: float) -> void:
	var fallback_top: float = sprite_y_offset - 100.0
	var fallback_bot: float = sprite_y_offset + 28.0
	_char_top_y = fallback_top
	_char_bottom_y = fallback_bot
	_char_height = fallback_bot - fallback_top

	if not frames.has_animation(&"idle"):
		return
	if frames.get_frame_count(&"idle") <= 0:
		return
	var tex: Texture2D = frames.get_frame_texture(&"idle", 0)
	if tex == null:
		return

	var frame_image: Image
	if tex is AtlasTexture:
		var atlas_tex: AtlasTexture = tex
		if atlas_tex.atlas == null:
			return
		var atlas_image: Image = atlas_tex.atlas.get_image()
		if atlas_image == null:
			return
		frame_image = atlas_image.get_region(atlas_tex.region)
	else:
		frame_image = tex.get_image()
	if frame_image == null:
		return

	var bounds: Rect2i = frame_image.get_used_rect()
	if bounds.size.y <= 0:
		return

	# Convert frame-pixel coords to unit-local y. The AnimatedSprite2D is
	# centered_texture by default, so the frame's pixel y=0 sits at
	# (sprite_y_offset - frame_h * sprite_scale / 2) in unit-local space.
	var frame_h: float = float(frame_image.get_height())
	var frame_top_local: float = sprite_y_offset - frame_h * sprite_scale * 0.5
	_char_top_y = frame_top_local + float(bounds.position.y) * sprite_scale
	_char_bottom_y = frame_top_local + float(bounds.position.y + bounds.size.y) * sprite_scale
	_char_height = _char_bottom_y - _char_top_y


## World position of a named anchor point on this unit. Anchors map to
## the actual character pixels (measured from the idle frame), so they
## stay correct across heroes (64px Mana Seed), goblins (16px 0x72),
## or any future sprite — no per-character tuning needed.
##
##   feet       — bottommost opaque pixel (ground contact)
##   center     — midpoint between feet and top of head (torso/chest)
##   head       — upper ~15% band (face / status icon row)
##   over_head  — 20px above the topmost pixel (damage numbers)
##   above      — 60px above the topmost pixel (status banner)
##
## Unknown anchor names log a warning and fall back to feet.
func get_anchor(anchor: StringName) -> Vector2:
	var local_y: float
	match anchor:
		&"feet":
			local_y = _char_bottom_y
		&"center":
			local_y = (_char_top_y + _char_bottom_y) * 0.5
		&"head":
			local_y = _char_top_y + _char_height * 0.15
		&"over_head":
			local_y = _char_top_y - 20.0
		&"above":
			local_y = _char_top_y - 60.0
		_:
			push_warning("[Unit] unknown anchor: %s" % anchor)
			local_y = _char_bottom_y
	return global_position + Vector2(0, local_y)


func set_hp(current: int, max_hp: int) -> void:
	var prev: float = _hp_bar.value
	_hp_bar.value = current
	_hp_label.text = "%d / %d" % [current, max_hp]
	_update_hp_color(current, max_hp)

	# Only play hit feedback if HP actually went DOWN (heals shouldn't shake).
	if current >= int(prev):
		return

	# Hit flash — bright red tint so the "ouch" reads at a glance.
	var flash := create_tween()
	if _using_anim_sprite:
		flash.tween_property(_anim_sprite, "modulate", Color(2.2, 0.6, 0.6, 1.0), 0.05)
		flash.tween_property(_anim_sprite, "modulate", Color.WHITE, 0.22)
	else:
		flash.tween_property(_sprite, "color", Color(1.6, 0.55, 0.55, 1.0), 0.05)
		flash.tween_property(_sprite, "color", _base_color, 0.22)

	# Scale punch on the sprite holder
	var punch := create_tween()
	punch.tween_property(_sprite_holder, "scale", Vector2(1.10, 0.88), 0.07)
	punch.tween_property(_sprite_holder, "scale", Vector2(1.0, 1.0), 0.16)

	# Position bump — bigger now so it reads on small enemies (goblins)
	# and the cleaner-art heroes alike.
	var bump_dist: float = 14.0
	# Bump AWAY from attacker would need to know direction; approximate with
	# a horizontal jolt in the direction of the hit indicator.
	var bump := create_tween()
	bump.tween_property(self, "position:x", position.x + bump_dist, 0.07).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	bump.tween_property(self, "position:x", position.x, 0.16).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)


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
		# Statuses don't persist past death — a corpse can't be burning
		# or stunned. Clear the StatusManager and tear down the badges.
		_clear_all_statuses()
		# Soul particles drifting up before the lying-down sprite
		# settles. Spawned on the parent so they outlive this unit.
		_spawn_death_effect()
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


func _clear_all_statuses() -> void:
	statuses.active.clear()
	for sid in _icons_by_status.keys():
		_icons_by_status[sid].queue_free()
	_icons_by_status.clear()
	# Burn ambient is a separate visual; clear it explicitly so a
	# burning unit's flame goes out when they die.
	_clear_burn_ambient()


## Soul-particles burst before the lying-down sprite settles. Spawned
## as a sibling (on the parent) so it survives even after the unit's
## sprite fades — the particles drift up independently for ~0.9s.
func _spawn_death_effect() -> void:
	var fx := DEATH_EFFECT_SCENE.instantiate()
	get_parent().add_child(fx)
	fx.global_position = get_anchor(&"center")


func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if _is_dead: return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("[Unit] click on %s" % _name_label.text)
		clicked.emit(self)


# ─── Status icon management ──────────────────────────────────────────

func add_status(status_id: String, duration: int, power: float, data: StatusEffectData) -> void:
	statuses.add(status_id, duration, power, data)
	_refresh_status_icons()
	if status_id == "burn":
		_ensure_burn_ambient()


func remove_status(status_id: String) -> void:
	statuses.remove(status_id)
	_refresh_status_icons()
	if status_id == "burn":
		_clear_burn_ambient()


## Spawn the looping flame as a child of this unit (so it follows the
## body through dashes). No-op if one is already present — burn can be
## refreshed on a unit that's already burning.
func _ensure_burn_ambient() -> void:
	if _burn_ambient != null and is_instance_valid(_burn_ambient):
		return
	_burn_ambient = BURN_AMBIENT_SCENE.instantiate()
	add_child(_burn_ambient)
	# Sit slightly below center (~10% of the character's height below
	# the midpoint). Reads as "the body is on fire" rather than putting
	# the flame in front of the face. Works for any sprite size since
	# it's relative to the measured character bounds.
	_burn_ambient.position = Vector2(0, _char_top_y + _char_height * 0.78)


func _clear_burn_ambient() -> void:
	if _burn_ambient != null and is_instance_valid(_burn_ambient):
		_burn_ambient.queue_free()
	_burn_ambient = null


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
