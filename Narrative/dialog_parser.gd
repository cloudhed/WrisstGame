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
			chunks.append({ "type": "narration", "text": narration })

		var quote = match.get_string(1)
		chunks.append({ "type": "speech", "text": quote })

		last_index = match.get_end()

	var tail = text.substr(last_index).strip_edges()
	if tail != "":
		chunks.append({ "type": "narration", "text": tail })

	return chunks
