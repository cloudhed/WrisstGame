extends EnemyAction

@export var damage := 3


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	var damage_effect := DamageEffect.new()
	var target_array: Array[Node] = [target]
	damage_effect.amount = damage
	damage_effect.sound = sound
	
	SFXPlayer.play(sound)
	
	Events.enemy_action_completed.emit(enemy)
