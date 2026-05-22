extends Node2D
## Slash arc VFX — plays Mana Seed's 4-frame slash animation.
##
## Frame timeline (60/60/100/100 ms):
##   F0  small wisp top-left  (sword anticipation)
##   F1  growing arc
##   F2  full arc (peak — sword tip passing)
##   F3  full arc settling (trailing visual)
## After the 4-frame animation finishes, fade out and free.
##
## Direction:
##   Default (flipped=false): arc bulges right.
##   Flipped (flipped=true): arc mirrored horizontally.

@onready var _anim: AnimatedSprite2D = $SlashAnim

const FADE_OUT := 0.14


func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)
	_anim.play(&"slash")


func _on_animation_finished() -> void:
	var tween := create_tween()
	tween.tween_property(_anim, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(queue_free)


## Mirror horizontally — flipping the animation flips every frame, so the
## entire 4-frame swing reads in the opposite direction.
func set_flipped(flipped: bool) -> void:
	_anim.flip_h = flipped
