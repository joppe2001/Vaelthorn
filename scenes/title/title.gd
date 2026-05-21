extends Control

@onready var _press_label: Label = $CenterContainer/VBox/PressAnyKey


func _ready() -> void:
	Game.transition_state(Game.State.TITLE)
	var tween := create_tween().set_loops()
	tween.tween_property(_press_label, "modulate:a", 0.3, 0.8)
	tween.tween_property(_press_label, "modulate:a", 1.0, 0.8)


func _input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		Game.change_scene("res://scenes/hub/hub.tscn")
