class_name DamageEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer:
			target.take_damage(amount)
			SFXPlayer.play(sound)

#added for showing amount on tile
func get_preview_amount() -> int:
	return amount
