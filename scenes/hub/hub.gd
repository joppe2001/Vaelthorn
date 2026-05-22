extends Control

@onready var _fps_label: Label = $TopBar/HBox/FPSLabel
@onready var _state_label: Label = $TopBar/HBox/StateLabel


func _ready() -> void:
	Game.transition_state(Game.State.HUB)


func _process(_delta: float) -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	_state_label.text = "State: HUB"


func _on_back_pressed() -> void:
	Game.change_scene("res://scenes/title/title.tscn")


func _on_battle_pressed() -> void:
	Game.change_scene("res://scenes/battle/battle.tscn")


func _on_heroes_pressed() -> void:
	Game.change_scene("res://scenes/hero_roster/hero_roster.tscn")
