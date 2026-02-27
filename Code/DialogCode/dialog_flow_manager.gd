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
var waiting_for_combat_end: bool = false
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
	if waiting_for_combat_end:
		return

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

	#if entry.get("type", "") == "command":
		#var cmd: String = entry.get("command", entry.get("text", ""))
		#if cmd is String and not cmd.is_empty():
			#handle_command(cmd)
#
		#await get_tree().process_frame
#
		#current_index = _find_entry_index_by_id(entry.get("next", "")) if entry.has("next") else current_index + 1
		#show_next_line()
		#return true
		
	if entry.get("type", "") == "command":
		var cmd: String = entry.get("command", entry.get("text", ""))
		var is_start_combat_entry: bool = _is_start_combat_command(cmd)
		if cmd is String and not cmd.is_empty():
			handle_command(cmd)

		await get_tree().process_frame
		
		apply_flags(entry)

		# Process flags
		show_next_chunk(entry)

		# If the entry had no chunks and didn't continue itself, move to next
		if chunk_list.is_empty():
			if is_start_combat_entry and _connect_combat_end_to_dialog_resume(entry):
				return true

			if entry.has("next"):
				var next_id: String = entry["next"]
				var next_index: int = _find_entry_index_by_id(next_id)
				if next_index != -1:
					current_index = next_index
					show_next_line()
					return true
			else:
				current_index += 1
				show_next_line()
				return true

		return true

	return false


func _is_start_combat_command(cmd: String) -> bool:
	if cmd.is_empty():
		return false

	for raw_cmd in cmd.split(";"):
		var trimmed := raw_cmd.strip_edges()
		if trimmed.trim_prefix("@").to_upper().begins_with("START_COMBAT"):
			return true

	return false


func _connect_combat_end_to_dialog_resume(entry: Dictionary) -> bool:
	var combat_node := _find_active_combat_node()
	if combat_node == null or not combat_node.has_signal("combat_ended"):
		return false

	var next_id: String = entry.get("next", "")
	combat_node.combat_ended.connect(
		Callable(self, "_on_blocking_combat_ended").bind(next_id),
		CONNECT_ONE_SHOT
	)
	waiting_for_combat_end = true
	waiting_for_input = false
	return true


func _find_active_combat_node() -> Node:
	var dialog_manager: Node = context.get("dialog_manager", null)
	if dialog_manager == null:
		return null

	for i in range(dialog_manager.get_child_count() - 1, -1, -1):
		var child: Node = dialog_manager.get_child(i)
		if child and child.has_signal("combat_ended"):
			return child

	return null


func _on_blocking_combat_ended(next_id: String) -> void:
	waiting_for_combat_end = false

	if not next_id.is_empty():
		var next_index: int = _find_entry_index_by_id(next_id)
		if next_index != -1:
			current_index = next_index
			show_next_line()
			return

	current_index += 1
	show_next_line()

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

		apply_flags(entry)

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
		"check_temp_flags_multi":
			var next_id: String = logic_handler.check_temp_flags_multi(entry)
			var next_index: int = _find_entry_index_by_id(next_id)
			if next_index != -1:
				current_index = next_index
				show_next_line()
		#"check_scene_from_multi":
			#var next_id: String = logic_handler.check_scene_from_multi(entry)
			#var next_index: int = _find_entry_index_by_id(next_id)
			#print(next_id, next_index)
			#if next_index != -1:
				#current_index = next_index
				#show_next_line()

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
	var condition: Variant = entry.get("condition", "")
	var target_id: String = ""

	if typeof(condition) == TYPE_STRING:
		var parts: PackedStringArray = condition.split(" ")
		if parts.is_empty():
			push_error("❌ Condition string is empty.")
			return

		var check: String = parts[0]

		match check:
			"HAS_ITEM":
				if parts.size() < 2:
					push_error("❌ HAS_ITEM missing item path.")
					return

				var item_path: String = parts[1]
				var item: InventoryItem = load("res://Resources/Items/%s.tres" % item_path) as InventoryItem
				var result: bool = item != null and GameState.has_item(item)
				target_id = entry.get("if_true", "") if result else entry.get("if_false", "")

			"HAS_REPUTATION":
				if parts.size() < 3:
					push_error("❌ HAS_REPUTATION missing parameters.")
					return

				var npc_id: String = parts[1]
				var required: int = parts[2].to_int()
				var current: int = GameState.get_reputation(npc_id)
				var result: bool = current >= required
				target_id = entry.get("if_true", "") if result else entry.get("if_false", "")

			_:
				push_error("❌ Unknown condition keyword: %s" % check)
				target_id = entry.get("if_false", "")

	elif typeof(condition) == TYPE_DICTIONARY:
		var condition_dict: Dictionary = condition
		if condition_dict.has("currency"):
			target_id = logic_handler.check_condition(entry)
		elif condition_dict.has("stat"):
			target_id = logic_handler.check_stat_condition(entry)
		else:
			push_error("❌ Unknown dictionary-style condition.")
			return

	else:
		push_error("❌ Invalid condition type: %s" % typeof(condition))
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
	# Support multiple commands split by semicolon
	for raw_cmd in cmd.split(";"):
		raw_cmd = raw_cmd.strip_edges()

		if not raw_cmd.begins_with("@"):
			print("⚠️ Skipping non-command:", raw_cmd)
			continue

		var command_context := context.duplicate()
		command_context["raw_command"] = raw_cmd
		command_context["name"] = dialogue[current_index].get("name", "")
		command_context["dialog_manager"] = context.get("dialog_manager", null)
		command_context["character_map"] = character_map
		command_context["slide_deck"] = slide_deck
		command_context["slide_container"] = context.get("slide_container", null)
		command_context["portrait_node"] = context.get("portrait_node", null)
		command_context["portrait2_node"] = context.get("portrait2_node", null)
		command_context["slideshow_node"] = context.get("slideshow_node", null)

		command_executor.execute(raw_cmd.trim_prefix("@"), command_context)


func apply_flags(entry: Dictionary) -> void:
	# Set flags
	if entry.has("set_flag"):
		var raw = entry["set_flag"]
		var flag_type: String = entry.get("flag_type", "quest")
		var flags_to_set: Array = []

		if typeof(raw) == TYPE_STRING:
			flags_to_set.append(raw)
		elif typeof(raw) == TYPE_ARRAY:
			flags_to_set = raw.duplicate()
		else:
			push_warning("⚠️ set_flag entry has invalid type.")

		for flag_name in flags_to_set:
			match flag_type:
				"dialog":
					GameState.set_flag(GameState.dialog_flags, flag_name)
				"event":
					GameState.set_flag(GameState.event_flags, flag_name)
				"temp":
					GameState.set_flag(GameState.temp_flags, flag_name)
				_:
					GameState.set_flag(GameState.quest_flags, flag_name)

	# Clear flags
	if entry.has("clear_flag"):
		var raw = entry["clear_flag"]
		var flags_to_clear: Array = []

		if typeof(raw) == TYPE_STRING:
			flags_to_clear.append(raw)
		elif typeof(raw) == TYPE_ARRAY:
			flags_to_clear = raw.duplicate()
		else:
			push_warning("⚠️ clear_flag entry has invalid type.")

		for flag_name in flags_to_clear:
			GameState.clear_flag(GameState.quest_flags, flag_name)
			GameState.clear_flag(GameState.dialog_flags, flag_name)
			GameState.clear_flag(GameState.temp_flags, flag_name)
			GameState.clear_flag(GameState.event_flags, flag_name)


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
