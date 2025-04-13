extends EnemyAction

@export var rage := 2


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var rage_effect := BlockEffect.new()
	rage_effect.amount = rage
	rage_effect.execute([enemy])
	
	emit_combat_message(enemy, target, message_template, rage)
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
