class_name Enums
## Project-wide enums.
##
## Imported via `Enums.Element.FIRE`, `Enums.HeroClass.HEALER`, etc.
## Keep this file small — only enums that span multiple systems live here.

enum Element {
	FIRE,
	WATER,
	EARTH,
	WIND,
	LIGHT,
	DARK,
}

enum HeroClass {
	ATTACKER,
	DEFENDER,
	HEALER,
	BUFFER,
	DEBUFFER,
	RANGER,
}

enum Tier {
	COMMON,      ## acquisition gray
	UNCOMMON,    ## green
	RARE,        ## blue
	EPIC,        ## purple
	LEGENDARY,   ## gold
	MYTHIC,      ## crimson
	CELESTIAL,   ## endgame-only, not summonable
}

enum TargetType {
	ENEMY_SINGLE,
	ENEMY_ALL,
	ALLY_SINGLE,
	ALLY_ALL,
	SELF,
}
