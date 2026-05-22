extends Node2D
## Debuff VFX — dark cracked ring with sharp jagged spokes.
##
## Spawned when a negative-modifier status (DEF_DOWN, ATK_DOWN, etc.) or
## a tick-damage status (Burn, Bleed) lands on a target. Different feel
## from the buff: jittery, cracked, expanding fast.

const LIFETIME := 0.9
const RING_RADIUS := 32.0
const RING_SEGMENTS := 16  # fewer segments + jitter = jagged "cracked" look
const SPOKE_COUNT := 6
const RING_COLOR := Color(0.18, 0.05, 0.28, 0.95)
const SPOKE_COLOR := Color(0.28, 0.08, 0.34, 0.85)


func _ready() -> void:
	_spawn_jagged_rings()
	_spawn_spokes()
	await get_tree().create_timer(LIFETIME).timeout
	queue_free()


func _spawn_jagged_rings() -> void:
	# Two rings, slightly offset, with jagged radius for a "cracked" feel.
	for i in 2:
		var ring := Line2D.new()
		ring.width = 3.0
		ring.default_color = RING_COLOR
		ring.closed = true
		ring.points = _jagged_circle(RING_RADIUS, RING_SEGMENTS, 5.0)
		ring.scale = Vector2(0.4, 0.4)
		add_child(ring)
		var delay: float = float(i) * 0.10
		var t := create_tween().set_parallel(true)
		t.tween_property(ring, "scale", Vector2(2.4, 2.4), 0.55) \
			.set_delay(delay).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(ring, "modulate:a", 0.0, 0.6).set_delay(delay + 0.05)


func _spawn_spokes() -> void:
	# Dark spikes shooting outward from center — adds aggression to the
	# debuff and prevents it from looking like a softer buff.
	for i in SPOKE_COUNT:
		var spoke := Line2D.new()
		spoke.width = 2.5
		spoke.default_color = SPOKE_COLOR
		var angle: float = TAU * float(i) / float(SPOKE_COUNT)
		spoke.points = PackedVector2Array([
			Vector2(cos(angle), sin(angle)) * 10.0,
			Vector2(cos(angle), sin(angle)) * 22.0,
		])
		add_child(spoke)
		var end_inner: Vector2 = Vector2(cos(angle), sin(angle)) * 32.0
		var end_outer: Vector2 = Vector2(cos(angle), sin(angle)) * 56.0
		var t := create_tween().set_parallel(true)
		t.tween_method(func(p: PackedVector2Array): spoke.points = p,
			spoke.points,
			PackedVector2Array([end_inner, end_outer]),
			0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		t.tween_property(spoke, "modulate:a", 0.0, 0.6).set_delay(0.1)


static func _jagged_circle(radius: float, segments: int, jitter: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a: float = TAU * float(i) / float(segments)
		var r: float = radius + randf_range(-jitter, jitter)
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts
