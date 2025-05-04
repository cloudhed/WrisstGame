extends Node
class_name DialogFlowManager

signal dialog_ended
signal jump_requested(target_id: String)

var dialogue: Array = []
var current_index: int = 0
var character_map: Dictionary[StringName, CharacterResource] = {}
var slide_deck: SlideDeck
var flags: Dictionary = {}

var line_spawner: DialogLineSpawner
var choice_box: ChoiceBox
var parser: DialogParser
var command_executor: DialogCommandExecutor
var logic_handler: DialogLogicHandler

var chunk_list: Array = []
var chunk_index: int = 0
var last_command_index: int = -1
var waiting_for_input: bool = false
var current_choice_entry: Dictionary = {}

var context: Dictionary = {}

func initialize(
	_dialogue: Array,
	_character_map: Dictionary,
	_slide_deck: SlideDeck,
	_flags: Dictionary,
	_context: Dictionary
) -> void:
	dialogue = _dialogue
	character_map = _character_map
	slide_deck = _slide_deck
	flags = _flags
	context = _context

	line_spawner = context.line_spawner
	choice_box = context.choice_box
	parser = context.parser
	command_executor = context.command_executor
	logic_handler = context.logic_handler

	# 🔌 Make sure these are in context so commands can access them
	context["portrait_node"] = context.get("portrait_node", null)
	context["portrait2_node"] = context.get("portrait2_node", null)
	context["slideshow_node"] = context.get("slideshow_node", null)
	context["slide_container"] = context.get("slide_container", null)

	if not choice_box.choice_selected.is_connected(choose):
		choice_box.choice_selected.connect(choose)

	current_index = 0
	chunk_list.clear()
	chunk_index = 0


func show_next_line() -> void:
	if check_dialog_end():
		return

	var entry: Dictionary = dialogue[current_index]
	choice_box.hide()

	if await handle_special_entry(entry):
		return

	handle_entry_command(entry)

	if show_next_chunk(entry):
		return

	process_entry_type(entry)

func check_dialog_end() -> bool:
	if current_index >= dialogue.size():
		print("✅ End of dialogue.")
		clear_dialog()
		emit_signal("dialog_ended")
		return true
	return false

func handle_special_entry(entry: Dictionary) -> bool:
	if entry.has("clear") and entry["clear"]:
		line_spawner.clear_lines()

	if entry.has("end") and entry["end"] == true:
		emit_signal("dialog_ended")
		clear_dialog()
		return true

	if entry.get("type", "") == "command":
		var cmd: String = entry.get("command", entry.get("text", ""))
		if cmd is String and not cmd.is_empty():
			handle_command(cmd)

		await get_tree().process_frame

		current_index = _find_entry_index_by_id(entry.get("next", "")) if entry.has("next") else current_index + 1
		show_next_line()
		return true

	return false

func handle_entry_command(entry: Dictionary) -> void:
	if entry.has("command") and typeof(entry["command"]) == TYPE_STRING and not entry["command"].is_empty():
		if current_index != last_command_index:
			handle_command(entry["command"])
			last_command_index = current_index

	if entry.has("text") and typeof(entry["text"]) == TYPE_STRING and current_index != last_command_index:
		var inline_commands = parser.parse_inline_commands(entry["text"])
		for cmd in inline_commands:
			handle_command(cmd)
		last_command_index = current_index

func show_next_chunk(entry: Dictionary) -> bool:
	if chunk_list.size() > 0 and chunk_index < chunk_list.size():
		var chunk = chunk_list[chunk_index]
		var speaker = entry.get("name", "")
		line_spawner.spawn_chunk(chunk, speaker, character_map)

		chunk_index += 1
		waiting_for_input = true
		return true

	if chunk_list.size() > 0 and chunk_index >= chunk_list.size():
		chunk_list.clear()
		chunk_index = 0

		if entry.has("set_flag"):
			var flag_name: String = entry["set_flag"]
			flags[flag_name] = true

		if entry.has("next"):
			var next_id: String = entry["next"]
			var next_index: int = _find_entry_index_by_id(next_id)
			if next_index != -1:
				current_index = next_index
				show_next_line()
				return true

		current_index += 1
		show_next_line()
		return true

	return false

func process_entry_type(entry: Dictionary) -> void:
	match entry.get("type", ""):
		"narration", "npc":
			chunk_list = parser.parse_dialog_chunks(entry.get("text", ""))
			chunk_index = 0
			begin_entry_chunks()
		"choice":
			current_choice_entry = entry
			choice_box.show_choices(entry.options)
			choice_box.show()
			waiting_for_input = false
		"logic":
			match entry.get("logic_type", "check_flags"):
				"check_flags":
					handle_flag_check(entry)
				"condition":
					handle_condition_check(entry)
				_:
					push_error("❌ Unknown logic_type in entry: " + entry.get("logic_type", ""))

func handle_flag_check(entry: Dictionary) -> void:
	var target_id: String = logic_handler.check_flags(entry, flags)
	if target_id.is_empty():
		push_error("❌ No valid target ID from flag check.")
		return

	var next_index: int = _find_entry_index_by_id(target_id)
	if next_index != -1:
		current_index = next_index
		show_next_line()
	else:
		push_error("❌ Could not find target ID after flag check.")

func handle_condition_check(entry: Dictionary) -> void:
	var condition_dict: Dictionary = entry.get("condition", {})
	var target_id: String = ""

	if condition_dict.has("currency"):
		target_id = logic_handler.check_condition(entry)
	elif condition_dict.has("stat"):
		target_id = logic_handler.check_stat_condition(entry)
	else:
		push_error("❌ Unknown condition type in logic entry.")
		return

	if target_id.is_empty():
		push_error("❌ No valid target ID from condition check.")
		return

	var next_index: int = _find_entry_index_by_id(target_id)
	if next_index != -1:
		current_index = next_index
		show_next_line()
	else:
		push_error("❌ Could not find target ID after condition check.")

func handle_command(cmd: String) -> void:
	if not cmd.begins_with("@"):
		print("⚠️ Skipping non-command tag:", cmd)
		return

	var command_context := context.duplicate()
	command_context["raw_command"] = cmd
	command_context["name"] = dialogue[current_index].get("name", "")
	command_context["dialog_manager"] = context.get("dialog_manager", null)
	command_context["character_map"] = character_map
	command_context["slide_deck"] = slide_deck
	command_context["slide_container"] = context.get("slide_container", null)
	command_context["portrait_node"] = context.get("portrait_node", null)
	command_context["portrait2_node"] = context.get("portrait2_node", null)
	command_context["slideshow_node"] = context.get("slideshow_node", null)

	command_executor.execute(cmd.trim_prefix("@"), command_context)

func choose(index: int) -> void:
	if current_choice_entry.is_empty():
		return

	clear_dialog()

	var next_id: String = current_choice_entry.options[index].next
	var next_index: int = _find_entry_index_by_id(next_id)
	if next_index == -1:
		push_error("❌ Next ID not found in dialogue.")
		return

	current_index = next_index
	current_choice_entry = {}
	show_next_line()

func _find_entry_index_by_id(id: String) -> int:
	for i in dialogue.size():
		if dialogue[i].has("id") and dialogue[i]["id"] == id:
			return i
	return -1

func clear_dialog() -> void:
	line_spawner.clear_lines()
	choice_box.hide()

func begin_entry_chunks() -> void:
	if chunk_list.size() > 0:
		var chunk = chunk_list[0]
		var speaker = dialogue[current_index].get("name", "")
		line_spawner.spawn_chunk(chunk, speaker, character_map)

		chunk_index = 1
		waiting_for_input = true

func jump_to_id(target_id: String) -> void:
	print("🚀 jump_to_id CALLED with:", target_id)  # ✅ ADD THIS
	var index := _find_entry_index_by_id(target_id)
	if index == -1:
		push_error("❌ jump_to_id: Entry not found: " + target_id)
		return

	current_index = index
	chunk_list.clear()
	chunk_index = 0
	show_next_line()
