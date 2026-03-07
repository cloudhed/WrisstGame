extends EnemyAction


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.sound = sound
	
	SFXPlayer.play(sound)
	
	Events.enemy_action_completed.emit(enemy)
