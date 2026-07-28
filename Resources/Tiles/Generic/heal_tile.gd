extends Tile

## Generic self-heal tile.
##
## Restores [member Tile.effect_amount] health to the player, clamped to their
## maximum by [HealEffect]. Used by restorative trinkets. Set the tile's target
## to SELF in the resource.
func apply_effects(targets: Array[Node]) -> void:
	var heal_effect := HealEffect.new()
	heal_effect.amount = effect_amount
	heal_effect.sound = sound
	heal_effect.execute(targets)

	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
