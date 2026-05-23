extends Control
## Hub — primary navigation screen.
##
## Top bar reads currency from SaveManager so the numbers reflect the
## player's actual save. Body has a primary CTA (Enter Battle) and two
## secondary destinations (Party Builder, Hero Roster). Footer shows
## FPS + a back-to-title escape hatch.
##
## v1 layout — grid of buttons. The eventual BF/Idle-Heroes pixel-art
## village swaps in here later (same destinations, just rendered as
## clickable buildings on a painted background). Save/load + the
## destinations themselves don't change.

@onready var _gold_label: Label = $TopBar/HBox/GoldLabel
@onready var _gems_label: Label = $TopBar/HBox/GemsLabel
@onready var _stamina_label: Label = $TopBar/HBox/StaminaLabel
@onready var _fps_label: Label = $Footer/HBox/FPSLabel


func _ready() -> void:
	Game.transition_state(Game.State.HUB)
	_refresh_currencies()


func _process(_delta: float) -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	# Cheap to refresh every frame — three label assignments. If we
	# later add per-frame allocations, gate this behind a signal from
	# SaveManager instead.
	_refresh_currencies()


func _refresh_currencies() -> void:
	_gold_label.text    = "Gold: %d"    % SaveManager.get_currency("gold")
	_gems_label.text    = "Gems: %d"    % SaveManager.get_currency("gems")
	_stamina_label.text = "Stamina: %d" % SaveManager.get_currency("stamina")


# ─── Navigation ──────────────────────────────────────────────────────

func _on_battle_pressed() -> void:
	# Routes through Party Builder so the player confirms their lineup
	# before the battle starts. battle.tscn falls back to a default
	# party if Game.selected_party_ids is empty, but the explicit step
	# makes "ENTER BATTLE" feel intentional.
	Game.change_scene("res://scenes/party_builder/party_builder.tscn")


func _on_party_pressed() -> void:
	Game.change_scene("res://scenes/party_builder/party_builder.tscn")


func _on_heroes_pressed() -> void:
	Game.change_scene("res://scenes/hero_roster/hero_roster.tscn")


func _on_back_pressed() -> void:
	Game.change_scene("res://scenes/title/title.tscn")
