extends Tile

## Generic combo tile: strike, then guard.
##
## Deals [member Tile.effect_amount] damage to the target, then grants
## [member Tile.secondary_effect_amount] block to the player. This is the
## generalized version of the Long Stick's two-handed block-strike — any big
## two-hander you can both swing and brace behind (e.g. the driftwood bough)
## can reuse it. Set the tile's target to SINGLE_ENEMY in the resource.
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
