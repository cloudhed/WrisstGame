extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = 1
	block_effect.sound = sound
	block_effect.execute(targets)
	
	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
