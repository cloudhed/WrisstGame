class_name BlockEffect
extends Effect

var amount := 0
var message_template := "You block [b][color=blue]{amount}[/color][/b] of incoming damage!" #added by me


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer: #START custom shit
			var name := target.name # fallback
			if "stats" in target and target.stats:
				name = target.stats.playername
			
			var message := message_template.format({
				"target_name": name,
				"amount": amount
			}) #END custom shit
			Events.emit_signal("combat_text_emitted", message) #emitting to eventmanager, to combat ui text
			target.stats.block += amount
