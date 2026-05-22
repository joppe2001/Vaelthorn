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
	var should_pop: bool = false
	var outline_size: int = 0
	var outline_color := Color.BLACK

	if is_crit:
		# Bright orange-red with a dark outline — reads "this hurt"
		color = Color(1.0, 0.45, 0.2)
		size = 48
		text = "✦ %d  CRIT!" % amount
		should_pop = true
		outline_size = 6
		outline_color = Color(0.18, 0.04, 0.0, 1.0)
	if is_lucky:
		# Bright mint green with green outline
		color = Color(0.55, 1.0, 0.7)
		size = 52
		text = "★ %d  LUCKY!" % amount
		should_pop = true
		outline_size = 6
		outline_color = Color(0.04, 0.18, 0.08, 1.0)

	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_font_size_override("font_size", size)
	if outline_size > 0:
		_label.add_theme_constant_override("outline_size", outline_size)
		_label.add_theme_color_override("font_outline_color", outline_color)

	# Float up + fade (always)
	var start_y := position.y
	var float_tween := create_tween().set_parallel(true)
	float_tween.tween_property(self, "position:y", start_y - 70, 0.7).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	float_tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.25)
	float_tween.chain().tween_callback(queue_free)

	# Pop-out scale (only on crit / lucky) — small -> oversized -> normal
	if should_pop:
		scale = Vector2(0.55, 0.55)
		var pop := create_tween()
		pop.tween_property(self, "scale", Vector2(1.30, 1.30), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(self, "scale", Vector2(1.0, 1.0), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func show_text(text: String, color: Color, size: int = 22) -> void:
	_label.text = text
	_label.add_theme_color_override("font_color", color)
	_label.add_theme_font_size_override("font_size", size)
	var start_y := position.y
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", start_y - 50, 0.7)
	tween.tween_property(self, "modulate:a", 0.0, 0.7).set_delay(0.3)
	tween.chain().tween_callback(queue_free)
