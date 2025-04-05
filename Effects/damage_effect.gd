class_name DamageEffect
extends Effect

var amount := 0
var message_template := "You hit the [b]{target_name}[/b] for [b][color=red]{amount}[/color][/b] damage!" #added by me


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer:
			
			#START custom shit 
			var name := target.name # fallback
			if "stats" in target and target.stats:
				name = target.stats.playername
			
			var message := message_template.format({
				"target_name": name,
				"amount": amount
			}) #END custom shit
			
			Events.emit_signal("combat_text_emitted", message) #emitting to eventmanager, to combat ui text
			target.take_damage(amount)

#added for showing amount on tile
func get_preview_amount() -> int:
	return amount
