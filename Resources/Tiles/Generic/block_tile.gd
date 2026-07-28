extends Tile

## Generic self-block tile.
##
## Grants [member Tile.effect_amount] block to whoever plays it. Used by every
## makeshift "shield" (barrel lid, bark slab, pot lid, sign board) and by any
## defensive trinket. Set the tile's target to SELF in the resource so the block
## lands on the player.
func apply_effects(targets: Array[Node]) -> void:
	var block_effect := BlockEffect.new()
	block_effect.amount = effect_amount
	block_effect.sound = sound
	block_effect.execute(targets)

	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
