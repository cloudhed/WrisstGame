class_name HealEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer: 
			if "health" in target.stats and "max_health" in target.stats:
				target.stats.health = min(target.stats.health + amount, target.stats.max_health)
#			target.stats.health += amount
func get_preview_amount() -> int:
	return amount
