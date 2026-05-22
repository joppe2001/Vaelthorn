extends PanelContainer
## Visual badge for one active status on a unit.
##
## Renders a pixel-art icon picked per-status from the Pimen pack(s).
## Each status id maps to a specific sheet + frame index — so ATK_UP
## shows a bicep, DEF_DOWN shows an arrow-pierced shield, etc.
##
## Statuses not in ICONS_BY_ID fall back to a generic buff (shield) or
## debuff (skull) icon, classified by StatusEffectData fields:
##   modifier_amount > 0  AND  tick_kind == NONE  AND  not skip_turn
##     -> generic buff icon
##   anything else
##     -> generic debuff icon

const BUFF_ATK_SHEET     := preload("res://assets/sprites/vfx/status/buff_atk.png")
const BUFF_SHIELD_SHEET  := preload("res://assets/sprites/vfx/status/buff_shield.png")
const DEBUFF_ARMOR_SHEET := preload("res://assets/sprites/vfx/status/debuff_armor.png")
const DEBUFF_STUN_SHEET  := preload("res://assets/sprites/vfx/status/debuff_stun.png")
const DEBUFF_SKULL_SHEET := preload("res://assets/sprites/vfx/status/debuff_skull.png")
const FIRE_BURST_SHEET   := preload("res://assets/sprites/vfx/elements/fire_burst.png")

# sheet, frame index, frame size (px). Pimen status sheets are 24x24,
# the fire-burst frames borrowed for Burn are 32x32 — the TextureRect
# scales both to fit the same on-screen badge.
const ICONS_BY_ID := {
	"atk_up":   {"sheet": BUFF_ATK_SHEET,     "frame": 2, "size": 24},
	"def_up":   {"sheet": BUFF_SHIELD_SHEET,  "frame": 5, "size": 24},
	"def_down": {"sheet": DEBUFF_ARMOR_SHEET, "frame": 6, "size": 24},
	"burn":     {"sheet": FIRE_BURST_SHEET,   "frame": 2, "size": 32},
	"stun":     {"sheet": DEBUFF_STUN_SHEET,  "frame": 4, "size": 24},
}
const GENERIC_BUFF   := {"sheet": BUFF_SHIELD_SHEET,  "frame": 5, "size": 24}
const GENERIC_DEBUFF := {"sheet": DEBUFF_SKULL_SHEET, "frame": 5, "size": 24}

@onready var _icon: TextureRect = $V/Icon
@onready var _turns: Label = $V/Turns

var _bg_style: StyleBoxFlat


func _ready() -> void:
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
	_start_pulse()


## Gentle scale + brightness pulse so the badge feels alive, not pasted.
## ~1.4s cycle, ~6% scale swing, runs forever (the parent queue_frees
## the icon when the status expires, which kills the tween with it).
func _start_pulse() -> void:
	_icon.pivot_offset = _icon.size * 0.5
	var tween := create_tween().set_loops()
	tween.tween_property(_icon, "scale", Vector2(1.06, 1.06), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_icon, "scale", Vector2(1.0, 1.0), 0.7) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func bind(data: StatusEffectData, turns: int) -> void:
	var entry: Dictionary = _pick_icon(data)
	var atlas := AtlasTexture.new()
	atlas.atlas = entry["sheet"]
	var size: int = entry["size"]
	atlas.region = Rect2(entry["frame"] * size, 0, size, size)
	_icon.texture = atlas
	_turns.text = str(turns)
	tooltip_text = "%s — %d turn%s" % [data.display_name, turns, "" if turns == 1 else "s"]


func set_turns(turns: int) -> void:
	_turns.text = str(turns)
	tooltip_text = tooltip_text.split(" — ")[0] + " — %d turn%s" % [turns, "" if turns == 1 else "s"]


## Look up the icon entry for a status. Returns the explicit per-id
## mapping if one exists; otherwise picks generic buff vs debuff based
## on the StatusEffectData fields.
func _pick_icon(data: StatusEffectData) -> Dictionary:
	if ICONS_BY_ID.has(data.id):
		return ICONS_BY_ID[data.id]
	var is_buff: bool = data.modifier_amount > 0.0 \
		and data.tick_kind == StatusEffectData.TickKind.NONE \
		and not data.skip_turn
	return GENERIC_BUFF if is_buff else GENERIC_DEBUFF
