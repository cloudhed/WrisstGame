extends EnemyAction

@export var damage := 4
@export var heal_amount := 3


func perform_action() -> void:
	if not enemy or not target:
		return
	
	var target_array: Array[Node] = [target]
	
	# Damage first
	var damage_effect := DamageEffect.new()
	damage_effect.amount = damage
	damage_effect.execute(target_array)
	
	# Heal second
	var heal_effect := HealEffect.new()
	heal_effect.amount = heal_amount
	heal_effect.execute([enemy])  # Healing self
	
	# Play VFX
	if enemy.has_node("ParticleVFX/LifestealVFX"):
		print("Lifesteal VFX!")
		enemy.lifesteal_vfx.restart()
	
	get_tree().create_timer(0.6, false).timeout.connect(
		func():
			Events.enemy_action_completed.emit(enemy)
	)
