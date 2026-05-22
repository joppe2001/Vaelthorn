extends Node2D
## Heal VFX — soft green glow + rising shimmer dots over the target.
##
## Spawned by battle.gd in _apply_result when a "heal" result lands.
## Self-frees after the animation completes. No external assets — all
## shapes are Polygon2D circles drawn at runtime so it stays GPU-cheap
## and ships without atlas work.

const LIFETIME := 1.0
const GLOW_RADIUS := 36.0
const SHIMMER_COUNT := 7
const SHIMMER_RISE := 150.0  # pixels of upward float
const HEAL_COLOR := Color(0.4, 1.0, 0.55, 0.95)
const GLOW_COLOR := Color(0.5, 1.0, 0.65, 0.55)


func _ready() -> void:
	_spawn_glow()
	_spawn_shimmer()
	# Self-destruct after the longest tween completes.
	await get_tree().create_timer(LIFETIME + 0.05).timeout
	queue_free()


func _spawn_glow() -> void:
	# Soft expanding disk behind the unit — sells "warmth is rising."
	var glow := Polygon2D.new()
	glow.polygon = _circle_polygon(GLOW_RADIUS, 28)
	glow.color = GLOW_COLOR
	glow.scale = Vector2(0.6, 0.6)
	add_child(glow)
	var t := create_tween().set_parallel(true)
	t.tween_property(glow, "scale", Vector2(2.2, 2.2), 0.55) \
		.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_property(glow, "modulate:a", 0.0, 0.65)


func _spawn_shimmer() -> void:
	# Seven tiny green motes that rise + fade with staggered delays so the
	# effect reads as a continuous shimmer rather than one burst.
	for i in SHIMMER_COUNT:
		var dot := Polygon2D.new()
		dot.polygon = _circle_polygon(5.0, 10)
		dot.color = HEAL_COLOR
		var x_off: float = randf_range(-28.0, 28.0)
		dot.position = Vector2(x_off, randf_range(-10.0, 10.0))
		add_child(dot)
		var delay: float = float(i) * 0.06
		var t := create_tween().set_parallel(true)
		t.tween_property(dot, "position:y",
			dot.position.y - SHIMMER_RISE - randf_range(-20.0, 20.0),
			0.85).set_delay(delay)
		t.tween_property(dot, "scale", Vector2(0.4, 0.4), 0.85).set_delay(delay)
		t.tween_property(dot, "modulate:a", 0.0, 0.85) \
			.set_delay(delay + 0.15)


static func _circle_polygon(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts
