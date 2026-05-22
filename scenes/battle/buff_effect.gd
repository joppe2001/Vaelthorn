extends Node2D
## Buff VFX — gold ring expanding outward + sparkle motes radiating.
##
## Spawned when a positive-modifier status (ATK_UP / DEF_UP / etc.) lands.
## Reads as "power gathering" around the caster. Self-frees.

const LIFETIME := 0.85
const RING_START_RADIUS := 40.0
const RING_SEGMENTS := 28
const SPARKLE_COUNT := 10
const RING_COLOR := Color(1.0, 0.85, 0.32, 0.92)
const SPARKLE_COLOR := Color(1.0, 0.95, 0.62, 1.0)


func _ready() -> void:
	_spawn_ring()
	_spawn_sparkles()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()


func _spawn_ring() -> void:
	# Hollow ring outline (Line2D) that scales out + fades. Two rings with
	# staggered delays so it pulses twice.
	for i in 2:
		var ring := Line2D.new()
		ring.width = 3.5
		ring.default_color = RING_COLOR
		ring.closed = true
		ring.points = _circle_points(RING_START_RADIUS, RING_SEGMENTS)
		ring.scale = Vector2(0.5, 0.5)
		add_child(ring)
		var delay: float = float(i) * 0.18
		var t := create_tween().set_parallel(true)
		t.tween_property(ring, "scale", Vector2(1.9, 1.9), 0.55) \
			.set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(ring, "modulate:a", 0.0, 0.55).set_delay(delay)


func _spawn_sparkles() -> void:
	# Diamond-shaped motes radiating outward from the caster center.
	for i in SPARKLE_COUNT:
		var spark := Polygon2D.new()
		spark.polygon = _diamond_polygon(4.0)
		spark.color = SPARKLE_COLOR
		var angle: float = TAU * float(i) / float(SPARKLE_COUNT) + randf_range(-0.2, 0.2)
		var start_r: float = randf_range(8.0, 14.0)
		spark.position = Vector2(cos(angle), sin(angle)) * start_r
		add_child(spark)
		var end_r: float = randf_range(48.0, 70.0)
		var end_pos: Vector2 = Vector2(cos(angle), sin(angle)) * end_r
		var t := create_tween().set_parallel(true)
		t.tween_property(spark, "position", end_pos, 0.6) \
			.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(spark, "modulate:a", 0.0, 0.6).set_delay(0.15)
		t.tween_property(spark, "rotation", randf_range(-PI, PI), 0.6)


static func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a: float = TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts


static func _diamond_polygon(size: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -size),
		Vector2(size, 0),
		Vector2(0, size),
		Vector2(-size, 0),
	])
