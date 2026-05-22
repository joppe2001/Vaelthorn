extends Node2D
## Buff VFX — Pimen "buff shield rises" pixel-art animation. Plays once
## when a positive-modifier status (ATK_UP / DEF_UP / etc.) lands on a
## unit. Self-frees after a short fade-out.
##
## Replaces the earlier code-driven gold-ring + sparkle version. The
## sprite-sheet animation matches the rest of the game's pixel style.

const FADE_OUT := 0.10

@onready var _anim: AnimatedSprite2D = $Anim


func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)
	if _anim.sprite_frames.has_animation(&"buff"):
		_anim.play(&"buff")


func _on_animation_finished() -> void:
	var tween := create_tween()
	tween.tween_property(_anim, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(queue_free)
