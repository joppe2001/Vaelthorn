extends Node
## Cross-scene signal hub. Loose coupling between systems.
##
## Listeners subscribe without knowing about emitters' scene paths.
## Add signals here as systems are introduced — never have a system
## reference another system's node directly when a signal would work.

## Combat events (Phase 1+)
signal combat_started(battle_id: String)
signal combat_ended(battle_id: String, victory: bool)
signal damage_dealt(attacker_id: String, target_id: String, amount: int, is_crit: bool)
signal heal_applied(target_id: String, amount: int)
signal status_applied(target_id: String, status_id: String)
signal unit_died(unit_id: String)

## Economy events (Phase 4+)
signal currency_changed(currency_id: String, new_amount: int, delta: int)
signal stamina_changed(new_amount: int)

## Hero events (Phase 3+)
signal hero_acquired(hero_id: String, instance_id: String)
signal hero_leveled(instance_id: String, new_level: int)
signal hero_ascended(instance_id: String, new_stars: int)
signal hero_promoted(instance_id: String, new_tier: int)

## UI events
signal toast_requested(message: String, kind: String) ## kind: info | warn | error | success
