class_name HealEffect
extends Effect

var amount := 0
var message_template := "{target_name} heals [b][color=green]{amount}[/color][/b] hitpoints." #added by me


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
			if "health" in target.stats and "max_health" in target.stats:
				target.stats.health = min(target.stats.health + amount, target.stats.max_health)
#			target.stats.health += amount
func get_preview_amount() -> int:
	return amount
