extends EnemyAction

const SET_STAMINA_EFFECT_SCRIPT := preload("res://Scripts/combat/effects/set_stamina_effect.gd")

@export var stamina_amount := 0


func is_performable() -> bool:
	if not target or not ("stats" in target):
		return false

	var target_stats = target.stats
	if target_stats == null or not ("stamina" in target_stats):
		return false

	return target_stats.stamina != stamina_amount


func perform_action() -> void:
	if not enemy or not target:
		return

	var stamina_effect = SET_STAMINA_EFFECT_SCRIPT.new()
	stamina_effect.sound = sound
	stamina_effect.amount = stamina_amount
	stamina_effect.execute([target])
	emit_combat_message(enemy, target, message_template, stamina_amount)
	Events.enemy_action_completed.emit(enemy)