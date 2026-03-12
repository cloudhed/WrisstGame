extends EnemyAction

@export var multiplier := 1.5


func is_performable() -> bool:
	return enemy != null and not enemy.has_combat_modifier(&"next_attack_multiplier")


func perform_action() -> void:
	if not enemy or not target:
		return

	enemy.set_combat_modifier(&"next_attack_multiplier", multiplier)
	emit_combat_message(enemy, target, message_template, int(round(multiplier * 100.0)))
	if sound:
		SFXPlayer.play(sound)
	Events.enemy_action_completed.emit(enemy)