extends Node
## Top-level game state and scene transitions.
##
## Autoloaded as `Game`. Owns the high-level state machine
## (title, hub, battle, ...) and provides scene transition helpers.

enum State { BOOT, TITLE, HUB, BATTLE, RESULTS, ROSTER, DETAIL, PARTY_BUILDER }

const VERSION := "0.0.1-phase0"
const PARTY_SIZE := 3

var current_state: State = State.BOOT

## Cross-scene data passing: set by Roster before transitioning to Detail.
var current_detail_hero_id: String = ""

## The 3 hero IDs that the next battle will use. Defaults to the original
## hardcoded party; Party Builder writes here. Empty strings mean "no hero
## in that slot" — battle.gd should fall back to defaults if anything is
## missing.
var selected_party_ids: PackedStringArray = PackedStringArray([
	"ember_knight", "crimson_lancer", "cinder_squire",
])

signal state_changed(from: State, to: State)


func _ready() -> void:
	print("[Game] booted — Vaelthorn ", VERSION)


func change_scene(path: String) -> void:
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[Game] scene change failed: %s (err=%d)" % [path, err])


func transition_state(to: State) -> void:
	var from := current_state
	current_state = to
	state_changed.emit(from, to)
	print("[Game] state ", State.keys()[from], " -> ", State.keys()[to])
