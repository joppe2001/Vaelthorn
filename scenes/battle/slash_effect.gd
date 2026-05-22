extends Node2D
## Slash arc VFX — appears at the impact point of a melee hit.
##
## The slash texture is the peak frame from Mana Seed's slash 1 animation.
## We don't run the full 4-frame anim here — we spawn at IMPACT only, so we
## use the peak arc and pop it in + fade it out. No rotation (that just made
## the arc look like it was spinning, which it wasn't supposed to).
##
## Direction:
##   Default (flipped=false): arc opens left, bulges right.
##     Use for: player on left attacking enemy on right.
##   Flipped (flipped=true): arc mirrored — opens right, bulges left.
##     Use for: enemy on right attacking player on left.

@onready var _sprite: Sprite2D = $Sprite

const POP_IN := 0.04
const HOLD := 0.10
const FADE_OUT := 0.20
const OVERSHOOT_SCALE := 1.15


func _ready() -> void:
	var target_scale: Vector2 = _sprite.scale
	_sprite.scale = target_scale * 0.4
	_sprite.modulate.a = 0.0

	var tween := create_tween()
	# Pop in: overshoot scale slightly, snap to opaque white
	tween.set_parallel(true)
	tween.tween_property(_sprite, "scale", target_scale * OVERSHOOT_SCALE, POP_IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "modulate:a", 1.0, POP_IN * 0.6)
	# Settle to target scale (the bounce-back from the overshoot)
	tween.chain().tween_property(_sprite, "scale", target_scale, 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Hold
	tween.chain().tween_interval(HOLD)
	# Fade out
	tween.chain().tween_property(_sprite, "modulate:a", 0.0, FADE_OUT)
	tween.chain().tween_callback(queue_free)


## Mirror horizontally so the arc opens toward the attacker's side.
func set_flipped(flipped: bool) -> void:
	_sprite.flip_h = flipped
