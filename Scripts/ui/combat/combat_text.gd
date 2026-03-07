extends Node

@onready var combat_text = $MarginContainer/CombatText as RichTextLabel

var message_queue: Array[String] = []
var is_typing: bool = false

func _ready() -> void:
	print("CombatTextUI ready")
	Events.connect("combat_text_emitted", Callable(self, "_on_combat_text_emitted"))


# Handles incoming message with typewriter effect
func _on_combat_text_emitted(message: String) -> void:
	message_queue.append(message)
	if not is_typing:
		_process_queue()


func _process_queue() -> void:
	while message_queue.size() > 0:
		is_typing = true
		var next_message: String = message_queue.pop_front()
		await type_line(next_message)
	is_typing = false


func parse_bbcode_line(line: String) -> Array:
	var result: Array = []
	var i = 0
	while i < line.length():
		if line[i] == "[":
			var end = line.find("]", i)
			if end == -1:
				break # malformed tag
			var tag = line.substr(i, end - i + 1)
			result.append({ "type": "tag", "value": tag })
			i = end + 1
		else:
			result.append({ "type": "text", "value": line[i] })
			i += 1
	return result


func type_line(line: String, speed: float = 0.005) -> void:
	var tokens = parse_bbcode_line(line)
	var previous_content: String = combat_text.text  # <--- save existing lines
	var current_text := ""
	var open_tags := []

	for token in tokens:
		if token["type"] == "tag":
			current_text += token["value"]
			if not token["value"].begins_with("[/"):
				open_tags.append(token["value"])
			else:
				if open_tags.size() > 0:
					open_tags.pop_back()
		elif token["type"] == "text":
			current_text += token["value"]
			combat_text.text = previous_content + current_text
			combat_text.scroll_to_line(combat_text.get_line_count())
			await get_tree().create_timer(speed).timeout

	# Finalize the line with a newline
	combat_text.text = previous_content + current_text + "\n"
	combat_text.scroll_to_line(combat_text.get_line_count())
