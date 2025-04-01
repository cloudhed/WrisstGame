extends Tile


func apply_effects(targets: Array[Node]) -> void:
	var fail_effect := FailEffect.new()
	fail_effect.amount = 0
	fail_effect.execute(targets)
