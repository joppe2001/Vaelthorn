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
	# SaveManager is also an autoload; its _ready may run AFTER ours
	# depending on declaration order. call_deferred guarantees the save
	# has been loaded from disk before we read it.
	call_deferred("_sync_from_save")


## Pull persisted state into the in-memory Game fields. Called once at
## boot via call_deferred. Future state (currency UI, hero unlocks)
## reads from SaveManager directly — only fields the runtime mutates
## frequently are mirrored here.
func _sync_from_save() -> void:
	var saved_party: PackedStringArray = SaveManager.get_party_ids()
	if saved_party.size() == PARTY_SIZE:
		selected_party_ids = saved_party
		print("[Game] restored party from save: ", selected_party_ids)


## Authoritative writer for party selection. Updates the in-memory
## Game field AND persists to disk. Callers (Party Builder, future
## auto-select flows) should use this, not direct assignment.
func set_party_ids(ids: PackedStringArray) -> void:
	selected_party_ids = ids
	SaveManager.set_party_ids(ids)


func change_scene(path: String) -> void:
	# Autosave at every scene boundary — covers party builder commit,
	# battle end, hub return, etc. without each caller having to know
	# about persistence.
	SaveManager.save()
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("[Game] scene change failed: %s (err=%d)" % [path, err])


func transition_state(to: State) -> void:
	var from := current_state
	current_state = to
	state_changed.emit(from, to)
	print("[Game] state ", State.keys()[from], " -> ", State.keys()[to])
