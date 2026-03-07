extends EnemyAction

@export var damage := 4
@export var heal_amount := 3

@export_multiline var damage_message_template := "[b]{source_name}[/b] drains [b][color=red]{amount}[/color][/b] health from [b]{target_name}[/b]!"
@export_multiline var heal_message_template := "[b]{source_name}[/b] absorbs [b][color=green]{amount}[/color][/b] HP!"

func perform_action() -> void:
	if not enemy or not target:
		return
	
	var target_array: Array[Node] = [target]
	
	# Damage first
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.sound = sound
	damage_effect.execute(target_array)
	
	emit_combat_message(enemy, target, damage_message_template, damage)
	
	# Heal second
	var heal_effect := HealEffect.new()
	heal_effect.amount = heal_amount
	heal_effect.execute([enemy])  # Healing self
	
	emit_combat_message(enemy, enemy, heal_message_template, heal_amount)
	
	# Play VFX
	if enemy.has_node("ParticleVFX/LifestealVFX"):
		print("Lifesteal VFX!")
		enemy.lifesteal_vfx.restart()
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
