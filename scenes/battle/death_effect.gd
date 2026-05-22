extends Node2D
## Death effect — small soul particles drifting up and fading when a
## unit hits 0 HP. Adds a moment of weight before the lying-down
## sprite settles.
##
## Code-driven (Polygon2D squares) rather than a sprite sheet because:
##   - It's a brief, generic effect that doesn't need element-specific
##     art.
##   - Pixelated white squares drifting up reads cleanly as "soul
##     escaping" without committing to a specific aesthetic.
##
## Lifetime ~0.9s. Self-frees.

const LIFETIME := 0.95
const PARTICLE_COUNT := 9
const PARTICLE_SIZE := 4.0
const RISE := 110.0


func _ready() -> void:
	_spawn_particles()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()


func _spawn_particles() -> void:
	# Pixelated white/grey squares rise and fade, slightly randomized.
	for i in PARTICLE_COUNT:
		var p := Polygon2D.new()
		var s: float = PARTICLE_SIZE if randi() % 2 == 0 else PARTICLE_SIZE * 0.7
		p.polygon = _square(s)
		p.color = Color(0.92, 0.92, 0.95, 0.95) if randi() % 3 != 0 \
			else Color(0.7, 0.7, 0.75, 0.85)
		var x_off: float = randf_range(-22.0, 22.0)
		p.position = Vector2(x_off, randf_range(-8.0, 8.0))
		add_child(p)
		var delay: float = float(i) * 0.04
		var rise: float = RISE + randf_range(-25.0, 25.0)
		var sway: float = randf_range(-15.0, 15.0)
		var t := create_tween().set_parallel(true)
		t.tween_property(p, "position",
			p.position + Vector2(sway, -rise), 0.85
		).set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate:a", 0.0, 0.85).set_delay(delay + 0.15)
		t.tween_property(p, "scale", Vector2(0.4, 0.4), 0.85).set_delay(delay + 0.20)


static func _square(s: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-s, -s),
		Vector2(s, -s),
		Vector2(s, s),
		Vector2(-s, s),
	])
