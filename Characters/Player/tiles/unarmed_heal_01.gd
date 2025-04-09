extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var heal_effect := HealEffect.new()
	heal_effect.amount = 2
	heal_effect.sound = sound
	heal_effect.execute(targets)
	
	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
