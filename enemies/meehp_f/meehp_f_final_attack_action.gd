extends EnemyAction

@export var damage := 16
@export var hp_threshold := 3

var already_used := false


func is_performable() -> bool:
	if not enemy or already_used:
		return false
	
	var is_low := enemy.stats.health <= hp_threshold
	already_used = is_low
	
	return is_low


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var damage_effect := DamageEffect.new()
	var start_pos := enemy.global_position
	var attack_offset := Vector2.LEFT * 12  # Adjust direction based on side!
	var attack_pos := start_pos + attack_offset
	
#	print("Attacking from", start_pos, "to", attack_pos)
	var tween := create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Step 1: Lunge forward
	tween.tween_property(enemy, "global_position", attack_pos, 0.1)
	
	# Step 2: Apply damage
	tween.tween_callback(func():
#		print("Tween midpoint: applying damage effect")
		var effect := DamageEffect.new()
		effect.amount = damage
		effect.execute([target])
		
		emit_combat_message(enemy, target, message_template, damage)
	)
	# Step 3: Move back to original position
	tween.tween_property(enemy, "global_position", start_pos, 0.1)
	
	# Step 4: End action
	tween.finished.connect(func():
#			print("Tween finished: attack action completed")
			Events.enemy_action_completed.emit(enemy)
	)
