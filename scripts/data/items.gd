class_name Items extends RefCounted
## Item registry. Currently just XP tonics — will grow as gear / shards /
## consumables land in later phases.
##
## Items live in SaveManager._state.inventory as a {item_id: count}
## dictionary. Look up an item's display info via Items.ITEMS[id].

const XP_POTION_SMALL  := "xp_potion_small"
const XP_POTION_MEDIUM := "xp_potion_medium"
const XP_POTION_LARGE  := "xp_potion_large"

## Each entry: name (display), xp (granted to hero), gold_cost (paid per
## use). Costs are deliberately low so the early game tests are
## frictionless; we'll tune them once we have a real economy.
const ITEMS := {
	XP_POTION_SMALL:  {"name": "Small XP Tonic",  "xp": 50,   "gold_cost": 10},
	XP_POTION_MEDIUM: {"name": "Medium XP Tonic", "xp": 250,  "gold_cost": 50},
	XP_POTION_LARGE:  {"name": "Large XP Tonic",  "xp": 1000, "gold_cost": 200},
}

## Item ids in display order — used by inventory UIs (the hero detail
## level-up panel, etc.) so the layout stays stable.
const DISPLAY_ORDER := [XP_POTION_SMALL, XP_POTION_MEDIUM, XP_POTION_LARGE]
