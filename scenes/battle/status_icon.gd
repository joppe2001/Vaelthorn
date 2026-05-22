extends PanelContainer
## Visual badge for one active status on a unit.
##
## Renders a pixel-art icon (Pimen buff/debuff packs) — frame 5 of the
## animation, the "settled" pose where the shield is up or the skull is
## pierced. Buff vs debuff is auto-detected from the StatusEffectData:
##
##   modifier_amount > 0  AND  tick_kind == NONE  AND  not skip_turn
##     -> buff icon (shield)
##   anything else
##     -> debuff icon (skull)
##
## Future: per-status icon override on StatusEffectData. For now,
## generic-by-type is enough to feel pixel-art native.

const BUFF_SHEET := preload("res://assets/sprites/vfx/status/buff_shield.png")
const DEBUFF_SHEET := preload("res://assets/sprites/vfx/status/debuff_skull.png")
const SETTLED_FRAME := 5            # peak/settled frame index in both packs
const FRAME_SIZE := 24

@onready var _icon: TextureRect = $V/Icon
@onready var _turns: Label = $V/Turns

var _bg_style: StyleBoxFlat


func _ready() -> void:
	# Subtle dark backdrop so the icon stays readable against bright
	# battle backgrounds. The icon itself carries the color/identity.
	_bg_style = StyleBoxFlat.new()
	_bg_style.bg_color = Color(0.05, 0.05, 0.08, 0.55)
	_bg_style.border_color = Color(0, 0, 0, 0.7)
	_bg_style.border_width_left = 1
	_bg_style.border_width_top = 1
	_bg_style.border_width_right = 1
	_bg_style.border_width_bottom = 1
	_bg_style.corner_radius_top_left = 3
	_bg_style.corner_radius_top_right = 3
	_bg_style.corner_radius_bottom_left = 3
	_bg_style.corner_radius_bottom_right = 3
	add_theme_stylebox_override("panel", _bg_style)


func bind(data: StatusEffectData, turns: int) -> void:
	var is_buff: bool = data.modifier_amount > 0.0 \
		and data.tick_kind == StatusEffectData.TickKind.NONE \
		and not data.skip_turn
	var sheet: Texture2D = BUFF_SHEET if is_buff else DEBUFF_SHEET
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(SETTLED_FRAME * FRAME_SIZE, 0, FRAME_SIZE, FRAME_SIZE)
	_icon.texture = atlas
	_turns.text = str(turns)
	tooltip_text = "%s — %d turn%s" % [data.display_name, turns, "" if turns == 1 else "s"]


func set_turns(turns: int) -> void:
	_turns.text = str(turns)
	tooltip_text = tooltip_text.split(" — ")[0] + " — %d turn%s" % [turns, "" if turns == 1 else "s"]
