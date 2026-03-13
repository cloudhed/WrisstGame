extends EnemyAction

const APPLY_COMBAT_STATUS_EFFECT_SCRIPT := preload("res://Scripts/combat/effects/apply_combat_status_effect.gd")

@export var stamina_amount := 0
@export var status_turns := 1


func is_performable() -> bool:
	if not target or not ("stats" in target):
		return false

	var target_stats = target.stats
	if target_stats == null or not target_stats.has_method("has_status"):
		return false

	if target_stats.has_status(&"drained_stamina"):
		var drained_status: Dictionary = target_stats.get_status(&"drained_stamina")
		return int(drained_status.get("stamina_amount", -1)) != stamina_amount

	return true


func perform_action() -> void:
	if not enemy or not target:
		return

	var status_effect = APPLY_COMBAT_STATUS_EFFECT_SCRIPT.new()
	status_effect.sound = sound
	status_effect.status_id = &"drained_stamina"
	status_effect.status_data = {
		"stamina_amount": stamina_amount,
		"remaining_turns": max(status_turns, 1)
	}
	status_effect.execute([target])
	emit_combat_message(enemy, target, message_template, stamina_amount)
	Events.enemy_action_completed.emit(enemy)