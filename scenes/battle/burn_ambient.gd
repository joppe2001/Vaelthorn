extends Node2D
## Burn ambient — small flame flickering above a unit that's burning.
##
## Lives as a child of the unit so it follows through dashes / position
## bumps automatically. unit.gd spawns one on add_status(burn, ...) and
## frees it on remove_status(burn) or when the unit dies.
##
## The flame loops through 4 frames of the existing fire_burst sheet
## (frames 1-4 are the visible flame body — frames 0 and 5-6 are pre/
## post-burst dispersal).

@onready var _anim: AnimatedSprite2D = $Anim


func _ready() -> void:
	if _anim.sprite_frames.has_animation(&"burn"):
		_anim.play(&"burn")
