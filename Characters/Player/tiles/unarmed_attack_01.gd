extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var damage_effect := DamageEffect.new()
	damage_effect.amount = 1
	damage_effect.execute(targets)
