extends Tile

## Generic single-target attack tile.
##
## Deals [member Tile.effect_amount] damage to the tile's target(s). Every blunt
## weapon's "hit" tile can point at this one script — the damage number, flavor
## text, art and sound all live in the .tres, so we never have to clone a new
## script per weapon. Set the tile's target to SINGLE_ENEMY in the resource.
func apply_effects(targets: Array[Node]) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = effect_amount
	damage_effect.sound = sound
	damage_effect.execute(targets)

	for each_target in targets:
		emit_combat_message(each_target, effect_amount)
