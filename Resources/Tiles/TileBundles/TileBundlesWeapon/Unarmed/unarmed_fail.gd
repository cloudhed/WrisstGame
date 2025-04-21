extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var fail_effect := FailEffect.new()
	fail_effect.amount = effect_amount
	fail_effect.sound = sound
	fail_effect.execute(targets)
	
	for target in targets:
		emit_combat_message(target, effect_amount)
