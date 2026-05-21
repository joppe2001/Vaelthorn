class_name EffectContext extends RefCounted
## Context passed to every Effect.apply() call.
##
## Effects are pure functions of context — no node references, no signal
## emission, no engine globals. The battle scene reads the result dict
## returned by apply() and is the only place side effects happen.
##
## This separation is what makes the combat core server-portable (Phase 9+).

var attacker: Dictionary
var target: Dictionary
var attacker_id: String
var target_id: String
var skill: SkillData
var rng: SeededRNG


func _init(
	attacker_stats: Dictionary,
	target_stats: Dictionary,
	atk_id: String,
	tgt_id: String,
	sk: SkillData,
	rng_: SeededRNG,
) -> void:
	attacker = attacker_stats
	target = target_stats
	attacker_id = atk_id
	target_id = tgt_id
	skill = sk
	rng = rng_
