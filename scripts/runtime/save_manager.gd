extends Node
## Read / write the local save file. Phase 1–8 only.
##
## Phase 9+ moves source of truth to the server; this manager becomes
## a cache. The migration chain stays append-only forever.
##
## Public surface:
##   get_state()              -> deep copy of the full state (debug)
##   save()                   -> write current state to disk
##   reload()                 -> re-read from disk (debug / tests)
##   reset_to_default()       -> wipe and recreate default state
##   get_party_ids()          -> persisted hero selection
##   set_party_ids(ids)       -> update selection + autosave
##   get_currency(name)       -> int amount (0 if missing)
##   add_currency(name, n)    -> increment, autosave
##   set_currency(name, n)    -> absolute, autosave

const SAVE_PATH := "user://save.json"
const CURRENT_VERSION := 1

var _state: Dictionary = {}


func _ready() -> void:
	load_from_disk()


func get_state() -> Dictionary:
	return _state.duplicate(true)


## Wholesale replace the state. Generally avoid this — prefer targeted
## helpers (set_party_ids, set_currency, etc.). Kept for tests and the
## rare migration scenario where a wholesale overwrite is correct.
func update_state(new_state: Dictionary) -> void:
	_state = new_state.duplicate(true)
	save_to_disk()


## Public alias for save_to_disk. Used by Game.change_scene() as the
## autosave hook so callers don't need to know which method they want.
func save() -> void:
	save_to_disk()


func reload() -> void:
	load_from_disk()


func reset_to_default() -> void:
	_state = _default_state()
	save_to_disk()


# ─── Party ───────────────────────────────────────────────────────────

func get_party_ids() -> PackedStringArray:
	var raw: Array = _state.get("selected_party_ids", [])
	var out := PackedStringArray()
	for id in raw:
		out.append(String(id))
	return out


func set_party_ids(ids: PackedStringArray) -> void:
	# Store as plain Array so JSON.stringify writes a clean array.
	var arr: Array = []
	for id in ids:
		arr.append(String(id))
	_state["selected_party_ids"] = arr
	save_to_disk()


# ─── Currency ────────────────────────────────────────────────────────

func get_currency(name: String) -> int:
	var bag: Dictionary = _state.get("currencies", {})
	return int(bag.get(name, 0))


func add_currency(name: String, amount: int) -> void:
	var bag: Dictionary = _state.get("currencies", {})
	bag[name] = int(bag.get(name, 0)) + amount
	_state["currencies"] = bag
	save_to_disk()


func set_currency(name: String, amount: int) -> void:
	var bag: Dictionary = _state.get("currencies", {})
	bag[name] = amount
	_state["currencies"] = bag
	save_to_disk()


# ─── Disk I/O ────────────────────────────────────────────────────────

func save_to_disk() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("[SaveManager] failed to open save for write (err=%d)" % FileAccess.get_open_error())
		return
	_state["save_version"] = CURRENT_VERSION
	_state["saved_at"] = Time.get_datetime_string_from_system(true)
	f.store_string(JSON.stringify(_state, "  "))
	f.close()


func load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_state = _default_state()
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_error("[SaveManager] failed to open save for read (err=%d)" % FileAccess.get_open_error())
		_state = _default_state()
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] save file corrupted, falling back to default")
		_state = _default_state()
		return
	_state = _migrate(parsed)
	# Backfill any keys that didn't exist when this save was written —
	# without this, calls to get_party_ids() on an old save would crash.
	for key in _default_state().keys():
		if not _state.has(key):
			_state[key] = _default_state()[key]


func _default_state() -> Dictionary:
	return {
		"save_version": CURRENT_VERSION,
		"player": {"name": "Player", "level": 1, "xp": 0},
		"currencies": {"gold": 0, "gems": 100, "stamina": 60},
		"selected_party_ids": ["ember_knight", "crimson_lancer", "cinder_squire"],
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
