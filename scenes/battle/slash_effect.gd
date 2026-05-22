extends Node2D
## Slash arc VFX — plays one of several Mana Seed slash animations.
##
## Three variants ship in the SpriteFrames:
##   slash1 — basic horizontal cut (default; matches the "Strike" feel)
##   slash2 — wider, more aggressive arc ("Flame Slash" / heavier swings)
##   thrust — tighter, faster jab ("Shatter" / piercing attacks)
## battle.gd picks the variant via spawn_with(anim_name) when spawning.
## After the animation finishes, fade out and free.

@onready var _anim: AnimatedSprite2D = $SlashAnim

const FADE_OUT := 0.14
const DEFAULT_ANIM := &"slash1"


func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)
	# If spawn_with wasn't called, just play the default.
	if not _anim.is_playing():
		_anim.play(DEFAULT_ANIM)


func _on_animation_finished() -> void:
	var tween := create_tween()
	tween.tween_property(_anim, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(queue_free)


## Mirror horizontally — flipping the animation flips every frame, so the
## entire 4-frame swing reads in the opposite direction.
func set_flipped(flipped: bool) -> void:
	_anim.flip_h = flipped


## Pick which slash variant to play. Falls back to slash1 if the requested
## animation doesn't exist.
func play_variant(anim_name: StringName) -> void:
	if _anim.sprite_frames.has_animation(anim_name):
		_anim.play(anim_name)
	else:
		_anim.play(DEFAULT_ANIM)
