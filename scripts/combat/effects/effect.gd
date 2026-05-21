class_name Effect extends Resource
## Base class for the Effect Composition system.
##
## Skills are NOT classes — they're lists of Effect atoms. Each Effect.apply()
## reads from EffectContext and returns a result dictionary describing what
## happened. The battle scene applies the visual side effects.
##
## Adding a hero with a new mechanic typically composes existing atoms.
## Adding a TRULY new mechanic costs one new Effect subclass — then it's
## available to every future skill forever.
##
## Result dictionary shapes:
##   {"kind": "damage", "target_id": str, "damage": int, "is_crit": bool,
##    "is_lucky": bool, "elemental_mult": float}
##   {"kind": "miss", "target_id": str}
##   {"kind": "status", "target_id": str, "status_id": str, "duration": int, "power": float}
##   {"kind": "status_resisted", "target_id": str, "status_id": str}
##   {"kind": "heal", "target_id": str, "amount": int}
##   {"kind": "none"}

enum Trigger {
	ON_USE,         ## fires when the skill is cast (the default)
	ON_HIT_TARGET,  ## fires per target hit by a previous damage effect
	ON_TURN_START,  ## passive — fires at the holder's turn start
	ON_TURN_END,    ## passive — fires at the holder's turn end
	ON_KILL,        ## fires when an effect's damage drops target to 0
	ON_DAMAGED,     ## fires when the holder takes damage
}

@export var trigger: Trigger = Trigger.ON_USE


## Override in subclasses. Pure function: read ctx, return a result dict.
## Do NOT mutate ctx or the world. The battle scene applies results.
func apply(_ctx: EffectContext) -> Dictionary:
	push_error("Effect.apply() must be overridden by %s" % get_script().resource_path)
	return {"kind": "none"}
