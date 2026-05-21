class_name StatusEffectData extends Resource
## A status that can be applied to a unit (Burn, Stun, ATK_UP, etc.).
##
## Loaded by ContentRegistry from data/status/. Applied via EffectStatus.
## Ticked at end-of-turn by StatusManager.

enum TickKind {
	NONE,                ## no per-turn tick (e.g. pure buffs)
	DOT_PERCENT_MAX_HP,  ## tick_amount % of target.MAX_HP as damage per turn (Burn, Bleed, Poison)
	DOT_FLAT,            ## flat damage per turn
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

## How this status ticks at the end of the holder's turn.
@export var tick_kind: TickKind = TickKind.NONE
## Magnitude (interpretation depends on tick_kind).
##   DOT_PERCENT_MAX_HP: percentage (e.g. 5.0 = 5% of max hp)
##   DOT_FLAT: flat damage
@export var tick_amount: float = 0.0

## If true, holder skips their next turn while this status is active.
@export var skip_turn: bool = false

## Visual: short letter shown in the status icon (e.g. "B" for Burn).
@export var icon_letter: String = "?"
## Visual: icon background color (we use this as a placeholder until real icons).
@export var icon_color: Color = Color(0.8, 0.3, 0.3, 1)

## Element classification — useful for damage tinting + future immunities.
@export_enum("NONE", "FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK") var element_tag: int = 0
