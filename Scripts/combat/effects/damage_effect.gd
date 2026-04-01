class_name DamageEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer:
			var damage_result: Dictionary = target.take_damage(amount)
			var armor_absorbed := int(damage_result.get("armor_absorbed", 0))
			var hp_dealt := int(damage_result.get("dealt", 0))
			var blocked := int(damage_result.get("blocked", 0))

			# Show armor absorption as a separate bronze popup
			if armor_absorbed > 0:
				Events.damage_popup_requested.emit(target.get_damage_popup_position(), armor_absorbed, "armor_absorbed")

			# Show HP damage (or blocked indicator)
			if hp_dealt > 0:
				var popup_type := "damage_blocked" if blocked > 0 else "damage"
				Events.damage_popup_requested.emit(target.get_damage_popup_position(), hp_dealt, popup_type)
			elif armor_absorbed == 0 and blocked > 0:
				Events.damage_popup_requested.emit(target.get_damage_popup_position(), 0, "damage_blocked")
			SFXPlayer.play(sound)

#added for showing amount on tile
func get_preview_amount() -> int:
	return amount
