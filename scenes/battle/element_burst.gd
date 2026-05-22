extends Node2D
## Element burst VFX — plays a pixel-art animation matching the skill's
## element (Pimen pixel-FX packs). Spawned alongside the slash arc when
## an elemental skill hits.
##
## Element index matches HeroData / SkillData enum:
##   0 FIRE   plays "fire"  anim
##   1 WATER  plays "water" anim
##   2 EARTH  plays "earth" anim
##   3 WIND   plays "wind"  anim
##   4 LIGHT  no anim (no asset yet — caller can skip spawning)
##   5 DARK   no anim (no asset yet)
##
## Self-frees after the animation finishes via a short fade-out.

const FADE_OUT := 0.10

const ELEMENT_TO_ANIM := {
	0: &"fire",
	1: &"water",
	2: &"earth",
	3: &"wind",
}

@onready var _anim: AnimatedSprite2D = $Anim


func _ready() -> void:
	_anim.animation_finished.connect(_on_animation_finished)


func _on_animation_finished() -> void:
	var tween := create_tween()
	tween.tween_property(_anim, "modulate:a", 0.0, FADE_OUT)
	tween.tween_callback(queue_free)


## Pick the burst animation for a given element index. Returns false if
## the element doesn't have a shipped pixel-art pack yet (caller should
## skip spawning rather than playing the wrong element).
func play_element(element: int) -> bool:
	if not ELEMENT_TO_ANIM.has(element):
		queue_free()
		return false
	var anim_name: StringName = ELEMENT_TO_ANIM[element]
	if not _anim.sprite_frames.has_animation(anim_name):
		queue_free()
		return false
	_anim.play(anim_name)
	return true
