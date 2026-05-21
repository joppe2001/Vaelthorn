extends Node
## Loads all data Resources at startup, indexes them by ID.
##
## Use `ContentRegistry.get_hero("ember_knight")` instead of preloading
## scattered paths. The registry is the single source of truth for
## content lookup; nothing else should `load()` a .tres directly.

var heroes: Dictionary = {}   ## id -> HeroData
var skills: Dictionary = {}   ## id -> SkillData
var weapons: Dictionary = {}  ## id -> WeaponData
var enemies: Dictionary = {}  ## id -> EnemyData
var items: Dictionary = {}    ## id -> ItemData
var stages: Dictionary = {}   ## id -> StageData
var statuses: Dictionary = {} ## id -> StatusEffectData


func _ready() -> void:
	_load_all("res://data/heroes/", heroes)
	_load_all("res://data/skills/", skills)
	_load_all("res://data/weapons/", weapons)
	_load_all("res://data/enemies/", enemies)
	_load_all("res://data/items/", items)
	_load_all("res://data/dungeons/", stages)
	_load_all("res://data/status/", statuses)
	print("[ContentRegistry] loaded:",
		" heroes=", heroes.size(),
		" skills=", skills.size(),
		" weapons=", weapons.size(),
		" enemies=", enemies.size(),
		" items=", items.size(),
		" stages=", stages.size(),
		" statuses=", statuses.size())


func get_hero(id: String) -> Resource:
	return heroes.get(id)


func get_skill(id: String) -> Resource:
	return skills.get(id)


func get_weapon(id: String) -> Resource:
	return weapons.get(id)


func get_enemy(id: String) -> Resource:
	return enemies.get(id)


func get_status(id: String) -> Resource:
	return statuses.get(id)


## Recursively load all .tres files in a folder.
## Files starting with `_` are treated as templates and skipped.
func _load_all(folder: String, target: Dictionary) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			_load_all(folder + entry + "/", target)
		elif entry.ends_with(".tres") and not entry.begins_with("_"):
			var res := load(folder + entry) as Resource
			if res != null and "id" in res and res.id != "":
				if target.has(res.id):
					push_error("[ContentRegistry] duplicate id: %s" % res.id)
				target[res.id] = res
		entry = dir.get_next()
	dir.list_dir_end()
