extends Tile

@export var optional_sound: AudioStream


func apply_effects(targets: Array[Node]) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = effect_amount
	damage_effect.sound = sound
	damage_effect.execute(targets)

	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
	
	var block_effect := BlockEffect.new()
	block_effect.amount = secondary_effect_amount
	block_effect.sound = optional_sound if optional_sound else sound
	block_effect.execute([source_stats.entity])
