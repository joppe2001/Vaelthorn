extends Control
## Hub — village world. Each clickable building leads to a destination.
##
## Buildings (Tiny Swords by Pixel Frog, free):
##   Castle      -> BATTLE   primary, biggest silhouette in the center
##   Tower       -> UPGRADE  forge / mage tower aesthetic
##   House Yel.  -> PARTY    cozy homestead / barracks
##   House Pur.  -> HEROES   roster — purple to read distinct from PARTY
##
## Top bar shows live currency from SaveManager so reward drops
## reflect immediately. Footer keeps FPS + back-to-title for now.
##
## Upgrade isn't implemented yet — the button routes to hero roster
## as a placeholder (the natural launch point once hero upgrade UI
## lands on a future hero detail revamp).

const HOVER_SCALE := 1.06

const GRASS_TILE := preload("res://assets/sprites/hub/terrain/grass_tile.png")
const SHEEP_IDLE_SHEET := preload("res://assets/sprites/hub/npcs/sheep_idle.png")
const SHEEP_FRAME_COUNT := 8
const SHEEP_FRAME_SIZE := 128
const SHEEP_POSITIONS := [
	Vector2(440, 660),
	Vector2(740, 670),
	Vector2(990, 660),
]

@onready var _gold_label: Label = $TopBar/HBox/GoldLabel
@onready var _gems_label: Label = $TopBar/HBox/GemsLabel
@onready var _stamina_label: Label = $TopBar/HBox/StaminaLabel
@onready var _fps_label: Label = $Footer/HBox/FPSLabel


func _ready() -> void:
	Game.transition_state(Game.State.HUB)
	_refresh_currencies()
	_upgrade_ground_to_tiled_grass()
	_spawn_sheep()
	# Pin pivot points so the hover scale grows from each building's
	# center, not its top-left corner.
	for btn_name in ["PartyBtn", "BattleBtn", "UpgradeBtn", "HeroesBtn"]:
		var btn: TextureButton = get_node(btn_name)
		btn.pivot_offset = btn.size * 0.5


## Swap the solid green Ground ColorRect for a tiled grass TextureRect
## that mirrors the same anchors/offsets, then drop the now-redundant
## highlight strip. Doing this in code (rather than editing hub.tscn)
## leaves all the user's editor-side positioning of buildings + deco
## intact.
func _upgrade_ground_to_tiled_grass() -> void:
	if not has_node("Ground"):
		return
	var old: Control = get_node("Ground")
	var ground := TextureRect.new()
	ground.name = "GrassGround"
	ground.texture = GRASS_TILE
	ground.stretch_mode = TextureRect.STRETCH_TILE
	ground.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Copy the original layout exactly.
	ground.anchor_top    = old.anchor_top
	ground.anchor_left   = old.anchor_left
	ground.anchor_right  = old.anchor_right
	ground.anchor_bottom = old.anchor_bottom
	ground.offset_top    = old.offset_top
	ground.offset_left   = old.offset_left
	ground.offset_right  = old.offset_right
	ground.offset_bottom = old.offset_bottom
	var idx: int = old.get_index()
	add_child(ground)
	move_child(ground, idx)
	old.queue_free()
	# Highlight strip becomes redundant with the textured grass.
	if has_node("GroundHighlight"):
		get_node("GroundHighlight").queue_free()


## Build the sheep idle SpriteFrames once, then instantiate animated
## sheep at the configured positions. Each sheep is a child of the
## hub Control — UI children (TopBar / Footer) are moved to stay on
## top via move_child.
func _spawn_sheep() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	for i in SHEEP_FRAME_COUNT:
		var t := AtlasTexture.new()
		t.atlas = SHEEP_IDLE_SHEET
		t.region = Rect2(i * SHEEP_FRAME_SIZE, 0, SHEEP_FRAME_SIZE, SHEEP_FRAME_SIZE)
		# 180ms/frame — chill, sleepy bounce
		frames.add_frame(&"idle", t, 0.18)

	# Find the top bar's tree position so we can drop sheep just above
	# the ground but below all UI overlays.
	var ui_index: int = get_child_count()
	if has_node("TopBar"):
		ui_index = min(ui_index, get_node("TopBar").get_index())
	if has_node("Footer"):
		ui_index = min(ui_index, get_node("Footer").get_index())

	for pos in SHEEP_POSITIONS:
		var sheep := AnimatedSprite2D.new()
		sheep.sprite_frames = frames
		sheep.animation = &"idle"
		sheep.scale = Vector2(0.7, 0.7)
		sheep.position = pos
		sheep.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sheep.play()
		add_child(sheep)
		move_child(sheep, ui_index)
		ui_index += 1  # keep subsequent sheep above earlier ones, still under UI


func _process(_delta: float) -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	_refresh_currencies()


func _refresh_currencies() -> void:
	_gold_label.text    = "Gold: %d"    % SaveManager.get_currency("gold")
	_gems_label.text    = "Gems: %d"    % SaveManager.get_currency("gems")
	_stamina_label.text = "Stamina: %d" % SaveManager.get_currency("stamina")


# ─── Navigation ──────────────────────────────────────────────────────

func _on_battle_pressed() -> void:
	Game.change_scene("res://scenes/party_builder/party_builder.tscn")


func _on_party_pressed() -> void:
	Game.change_scene("res://scenes/party_builder/party_builder.tscn")


func _on_heroes_pressed() -> void:
	Game.change_scene("res://scenes/hero_roster/hero_roster.tscn")


func _on_upgrade_pressed() -> void:
	# Placeholder — once the proper hero upgrade screen lands, point at
	# it instead. For now we route to roster so the click still feels
	# productive.
	Game.change_scene("res://scenes/hero_roster/hero_roster.tscn")


func _on_back_pressed() -> void:
	Game.change_scene("res://scenes/title/title.tscn")


# ─── Hover feedback ──────────────────────────────────────────────────

## Quick scale tween on hover so buildings feel responsive. Uses
## binds= to identify which button — keeps the .tscn connection
## table compact (one method handles all four buildings).
func _on_btn_hover(btn_name: String, hovered: bool) -> void:
	var btn: TextureButton = get_node(btn_name)
	var target: float = HOVER_SCALE if hovered else 1.0
	var t := create_tween()
	t.tween_property(btn, "scale", Vector2(target, target), 0.12) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
