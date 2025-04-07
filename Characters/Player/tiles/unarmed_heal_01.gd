extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var heal_effect := HealEffect.new()
	heal_effect.amount = 2
	heal_effect.execute(targets)
