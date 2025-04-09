extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = 4
	damage_effect.sound = sound
	damage_effect.execute(targets)

	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
