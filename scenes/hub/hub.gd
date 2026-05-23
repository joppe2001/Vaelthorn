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

@onready var _gold_label: Label = $TopBar/HBox/GoldLabel
@onready var _gems_label: Label = $TopBar/HBox/GemsLabel
@onready var _stamina_label: Label = $TopBar/HBox/StaminaLabel
@onready var _fps_label: Label = $Footer/HBox/FPSLabel


func _ready() -> void:
	Game.transition_state(Game.State.HUB)
	_refresh_currencies()
	# Pin pivot points so the hover scale grows from each building's
	# center, not its top-left corner.
	for btn_name in ["PartyBtn", "BattleBtn", "UpgradeBtn", "HeroesBtn"]:
		var btn: TextureButton = get_node(btn_name)
		btn.pivot_offset = btn.size * 0.5


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
