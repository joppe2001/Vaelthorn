extends Node
## Read / write the local save file. Phase 1–8 only.
##
## Phase 9+ moves source of truth to the server; this manager becomes
## a cache. The migration chain stays append-only forever.

const SAVE_PATH := "user://save.json"
const CURRENT_VERSION := 1

var _state: Dictionary = {}


func _ready() -> void:
	load_from_disk()


func get_state() -> Dictionary:
	return _state.duplicate(true)


func update_state(new_state: Dictionary) -> void:
	_state = new_state.duplicate(true)
	save_to_disk()


func save_to_disk() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] failed to open save for write")
		return
	_state["save_version"] = CURRENT_VERSION
	_state["saved_at"] = Time.get_datetime_string_from_system(true)
	f.store_string(JSON.stringify(_state, "  "))


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_state = _default_state()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("[SaveManager] failed to open save for read")
		_state = _default_state()
		return
	var text := f.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] save file corrupted, falling back to default")
		_state = _default_state()
		return
	_state = _migrate(parsed)


func _default_state() -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"player": {"name": "Player", "level": 1, "xp": 0},
		"currencies": {"gold": 0, "gems": 100, "stamina": 60},
		"heroes": [],
		"weapons": [],
		"gear_inventory": [],
		"settings": {"master_vol": 0.8, "music_vol": 0.7, "sfx_vol": 1.0},
	}


## Migration chain. Add new steps as the save format evolves.
## NEVER remove a migration step — players returning after months
## of absence still need to load.
func _migrate(save: Dictionary) -> Dictionary:
	var version := int(save.get("save_version", 0))
	while version < CURRENT_VERSION:
		match version:
			# 0:
			#     save = _v0_to_v1(save)
			#     version = 1
			_:
				push_warning("[SaveManager] no migration path from v%d" % version)
				break
	return save
