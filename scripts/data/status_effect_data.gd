class_name StatusEffectData extends Resource
## A status that can be applied to a unit (Burn, Stun, ATK_UP, etc.).
##
## Loaded by ContentRegistry from data/status/. Applied via EffectStatus.
## Statuses can do up to three things while active:
##   1. Tick at end-of-turn (DoT damage)        -> tick_kind + tick_amount
##   2. Modify a stat passively                 -> modifier_kind + modifier_amount
##   3. Skip the holder's turn                  -> skip_turn = true
## A status can do any combination (e.g. "Bleeding Frenzy" could DoT + buff
## ATK simultaneously — uncommon but supported).

enum TickKind {
	NONE,                ## no per-turn tick (pure buffs / pure stuns)
	DOT_PERCENT_MAX_HP,  ## tick_amount % of target.MAX_HP as damage per turn (Burn, Bleed, Poison)
	DOT_FLAT,            ## flat damage per turn
}

enum ModifierKind {
	NONE,
	ATK_PCT,        ## modifier_amount = % change (e.g. 30 = +30%, -30 = -30%)
	DEF_PCT,
	SPD_PCT,
	ACC_PCT,
	EVA_PCT,
	CRIT_RATE_PCT,
}

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("End-of-turn tick")
@export var tick_kind: TickKind = TickKind.NONE
@export var tick_amount: float = 0.0

@export_group("Passive stat modifier (applies while status is on)")
@export var modifier_kind: ModifierKind = ModifierKind.NONE
## Percentage: positive = buff, negative = debuff.
@export var modifier_amount: float = 0.0

@export_group("Other")
## If true, holder skips their turn while this status is active.
@export var skip_turn: bool = false

@export_group("Visuals")
@export var icon_letter: String = "?"
@export var icon_color: Color = Color(0.8, 0.3, 0.3, 1)
@export_enum("NONE", "FIRE", "WATER", "EARTH", "WIND", "LIGHT", "DARK") var element_tag: int = 0
