extends EnemyAction

@export var min_damage := 4
@export var max_damage := 6


func perform_action() -> void:
	if not enemy or not target:
		return

	var damage := get_modified_damage(randi_range(min_damage, max_damage))
	var start_pos := enemy.global_position
	var attack_offset := Vector2.LEFT * 12
	var attack_pos := start_pos + attack_offset

	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	tween.tween_property(enemy, "global_position", attack_pos, 0.1)

	tween.tween_callback(func():
		var effect := DamageEffect.new()
		effect.amount = damage
		effect.sound = sound
		effect.execute([target])

		emit_combat_message(enemy, target, message_template, damage)
	)

	tween.tween_property(enemy, "global_position", start_pos, 0.1)

	tween.finished.connect(func():
		Events.enemy_action_completed.emit(enemy)
	)
