extends Tile

## Generic miss / "fail" tile.
##
## Does nothing mechanically — it just plays a sound and a flavor line. Padding
## copies of a miss tile into a weapon's bundle is how we tune *reliability*:
## more misses make a weapon less dependable (e.g. the hard-to-aim sling),
## independently of how hard its hits land. Set the tile's target to SELF so it
## resolves without asking the player to pick an enemy to whiff at.
func apply_effects(targets: Array[Node]) -> void:
	var fail_effect := FailEffect.new()
	fail_effect.amount = effect_amount
	fail_effect.sound = sound
	fail_effect.execute(targets)

	for target in targets:
		emit_combat_message(target, effect_amount)
