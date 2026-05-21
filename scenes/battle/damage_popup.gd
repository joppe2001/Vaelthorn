extends Node2D
## Floating damage number — spawn, tween up + fade, free.
##
## Phase 1 form: white normal / gold crit / green lucky. Future polish:
## screen shake on crit (camera), particle bursts, hit sparks.

@onready var _label: Label = $Label


func show_damage(amount: int, is_crit: bool, is_lucky: bool) -> void:
	var text := str(amount)
	var color := Color.WHITE
	var size := 26

	if is_crit:
		color = Color(0.99, 0.83, 0.26)
		size = 40
		text = "%d!" % amount
	if is_lucky:
		color = Color(0.55, 1.0, 0.7)
		size = 44
		text = "★ %d" % amount

	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_font_size_override("font_size", size)

	var start_y := position.y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", start_y - 70, 0.7).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.25)
	tween.chain().tween_callback(queue_free)


func show_text(text: String, color: Color, size: int = 22) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_font_size_override("font_size", size)
	var start_y := position.y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", start_y - 50, 0.7)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
