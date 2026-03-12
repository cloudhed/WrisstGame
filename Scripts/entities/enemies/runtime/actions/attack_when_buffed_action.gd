extends EnemyAction

@export var min_damage := 1
@export var max_damage := 2


func is_performable() -> bool:
	return enemy != null and enemy.has_combat_modifier(&"next_attack_multiplier")


func perform_action() -> void:
	if not enemy or not target:
		return

	var damage := get_modified_damage(randi_range(min_damage, max_damage))
	var effect := DamageEffect.new()
	effect.amount = damage
	effect.sound = sound
	effect.execute([target])
	emit_combat_message(enemy, target, message_template, damage)
	Events.enemy_action_completed.emit(enemy)