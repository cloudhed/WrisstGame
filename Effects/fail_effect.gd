class_name FailEffect
extends Effect

var amount := 0
#start of random message things # not the best way to do things, there is the shuffle bag method too.
# Im thinking there should be a central thing firing, and just checking what classname the effect has.
var _last_message_index := 1 
var messages := [
	"You clumsily wave your fists around, hitting only air. But hey, at least the air has learned not to pick a fight with you, huh?",
	"You hit the enemy for... 0 damage. [i]Wow.[/i] Not your day.",
	"Your attack lands somewhere else. Perhaps in the bushes.",
	"You miss. Spectacularly.",
	"You flail like a noodle in the wind. It's not very effective.",
	"Your target watches in confusion as you punch a tree instead.",
	"You nearly hit yourself. Bold move.",
]

func get_new_random_message() -> String:
	if messages.size() <= 1:
		return messages[0]
	
	var new_index := _last_message_index
	while new_index == _last_message_index:
		new_index = randi() % messages.size()
		
	_last_message_index = new_index
	return messages[new_index] #end of random message things


func execute(targets: Array[Node]) -> void:
	for target in targets:
		if not target:
			continue
		if target is Enemy or target is CombatPlayer:
				var message := get_new_random_message() #part of RandomMessage
				Events.emit_signal("combat_text_emitted", message) #emitting to eventmanager, to combat ui text
#				target.take_damage(amount)
