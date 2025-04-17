class_name DialogParser
extends Object

func parse_dialog_chunks(text: String) -> Array:
	var chunks: Array = []
	var regex = RegEx.new()
	regex.compile(r'"(.*?)"')
	var matches = regex.search_all(text)
	var last_index = 0

	for match in matches:
		var narration = text.substr(last_index, match.get_start() - last_index).strip_edges()
		if narration != "":
			var narration_parts = narration.split("[nb]")
			for part in narration_parts:
				chunks.append({ "type": "narration", "text": part.strip_edges() })

		var quote = match.get_string(1)
		chunks.append({ "type": "speech", "text": quote })

		last_index = match.get_end()

	var tail = text.substr(last_index).strip_edges()
	if tail != "":
		var tail_parts = tail.split("[nb]")
		for part in tail_parts:
			chunks.append({ "type": "narration", "text": part.strip_edges() })
	
	print("🧩 Parsed chunks:", chunks)
	return chunks


func parse_inline_commands(text: String) -> Array:
	var commands: Array = []
	var pattern = RegEx.new()
	pattern.compile(r"\[(.+?)\]")  # matches [add_ore 5], etc.
	var matches = pattern.search_all(text)

	for match in matches:
		var cmd = match.get_string(1)
		commands.append(cmd)

	return commands
