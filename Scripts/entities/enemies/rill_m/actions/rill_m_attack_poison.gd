extends EnemyAction

const APPLY_COMBAT_STATUS_EFFECT_SCRIPT := preload("res://Scripts/combat/effects/apply_combat_status_effect.gd")

@export var poison_damage := 1
@export_range(1, 10) var poison_turns := 4


func is_performable() -> bool:
	if not target or not ("stats" in target):
		return false

	var target_stats = target.stats
	if target_stats == null or not target_stats.has_method("has_status"):
		return false

	return not target_stats.has_status(&"poison")


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var poison_effect = APPLY_COMBAT_STATUS_EFFECT_SCRIPT.new()
	poison_effect.sound = sound
	poison_effect.status_id = &"poison"
	poison_effect.status_data = {
		"damage": poison_damage,
		"remaining_turns": poison_turns
	}
	poison_effect.execute([target])
	emit_combat_message(enemy, target, message_template, poison_damage)
	
	Events.enemy_action_completed.emit(enemy)
