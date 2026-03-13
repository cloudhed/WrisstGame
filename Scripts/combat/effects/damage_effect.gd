class_name DamageEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer:
			var damage_result: Dictionary = target.take_damage(amount)
			var popup_amount := int(damage_result.get("dealt", 0))
			var popup_type := "damage_blocked" if int(damage_result.get("blocked", 0)) > 0 else "damage"
			Events.damage_popup_requested.emit(target.get_damage_popup_position(), popup_amount, popup_type)
			SFXPlayer.play(sound)

#added for showing amount on tile
func get_preview_amount() -> int:
	return amount
