extends CanvasLayer
## Ultimate cut-in — short cinematic shown when a hero fires their ultimate.
##
## Sequence:
##   t=0.00  dim layer fades in over 120ms
##   t=0.06  diagonal accent slash sweeps in from off-screen left (180ms)
##   t=0.10  banner + names slide in from the right (220ms)
##   t=0.50  hold (260ms)
##   t=0.76  everything fades out (180ms)
##   t=0.94  emit `done` and queue_free
##
## The whole thing fits in under a second so it doesn't interrupt the
## tempo of a turn-based fight. battle.gd awaits the `done` signal
## before kicking off the actual ult swing.

signal done

const DIM_FADE_IN := 0.12
const ACCENT_SWEEP_IN := 0.18
const BANNER_SLIDE_IN := 0.22
const HOLD := 0.26
const FADE_OUT := 0.18

@onready var _dim: ColorRect = $Dim
@onready var _accent: ColorRect = $Accent
@onready var _banner_wrap: Control = $BannerWrap
@onready var _ult_label: Label = $BannerWrap/UltLabel
@onready var _caster_label: Label = $BannerWrap/CasterLabel


func _ready() -> void:
	# Banner starts off-screen right, accent starts off-screen left.
	var vp := get_viewport().get_visible_rect().size
	_banner_wrap.position.x = vp.x + 40.0
	_accent.position.x = -vp.x
	_dim.modulate.a = 0.0
	_accent.modulate.a = 0.0
	_banner_wrap.modulate.a = 0.0


## Run the full cut-in sequence. Caller awaits the returned `done` signal.
func play(ult_name: String, caster_name: String, accent_color: Color) -> void:
	_ult_label.text = ult_name.to_upper()
	_caster_label.text = caster_name
	_accent.color = accent_color

	var vp := get_viewport().get_visible_rect().size
	var dim_target_a: float = 0.78
	var t := create_tween().set_parallel(true)
	# 1. dim
	t.tween_property(_dim, "modulate:a", dim_target_a, DIM_FADE_IN)
	# 2. accent slash sweeps across
	t.tween_property(_accent, "modulate:a", 1.0, 0.06).set_delay(0.04)
	t.tween_property(_accent, "position:x", vp.x * 0.10, ACCENT_SWEEP_IN) \
		.set_delay(0.06).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	# 3. banner slides in
	t.tween_property(_banner_wrap, "modulate:a", 1.0, 0.10).set_delay(0.10)
	t.tween_property(_banner_wrap, "position:x", vp.x * 0.5 - _banner_wrap.size.x * 0.5, BANNER_SLIDE_IN) \
		.set_delay(0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Hold, then fade out.
	await get_tree().create_timer(DIM_FADE_IN + ACCENT_SWEEP_IN + HOLD).timeout
	var fade := create_tween().set_parallel(true)
	fade.tween_property(_dim, "modulate:a", 0.0, FADE_OUT)
	fade.tween_property(_accent, "modulate:a", 0.0, FADE_OUT)
	fade.tween_property(_banner_wrap, "modulate:a", 0.0, FADE_OUT)
	await get_tree().create_timer(FADE_OUT).timeout
	done.emit()
	queue_free()
