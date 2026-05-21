extends Node2D
## A single slash arc VFX. Spawned when a melee hit lands.
##
## Phase 1.5c stand-in for real attack-frame animations. Plays one slash
## arc texture, scales up + fades out + rotates slightly, then frees itself.
## When Phase 2 ships frame-by-frame attack animations, this stays as
## layered VFX on top — the slash arc IS the impact, not the swing.

@onready var _sprite: Sprite2D = $Sprite

const DURATION := 0.32


func _ready() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_sprite, "scale", _sprite.scale * 1.4, DURATION * 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, "rotation", _sprite.rotation + deg_to_rad(25), DURATION * 0.8)
	tween.tween_property(_sprite, "modulate:a", 0.0, DURATION).set_delay(DURATION * 0.4)
	tween.chain().tween_callback(queue_free)


## Flip the slash horizontally for left-facing impacts (e.g. enemy hits player).
func set_flipped(flipped: bool) -> void:
	_sprite.flip_h = flipped
