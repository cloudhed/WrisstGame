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
			var filtered_options: Array = _filter_choice_options(entry.get("options", []))
			current_choice_entry = entry.duplicate(true)
			current_choice_entry["options"] = filtered_options

			if filtered_options.is_empty():
				push_warning("⚠️ Choice entry has no visible options after show/hide filtering.")
				if entry.has("next"):
					var next_id: String = entry["next"]
					var next_index: int = _find_entry_index_by_id(next_id)
					if next_index != -1:
						current_index = next_index
						show_next_line()
						return
				current_index += 1
				show_next_line()
				return

			choice_box.show_choices(filtered_options)
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
		"check":
			_resolve_standalone_check(entry)
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

			"HAS_SPECIES_STAT":
				# Usage: "condition": "HAS_SPECIES_STAT meehp sex 1"
				# Stat can be: sex, wins, losses, met
				if parts.size() < 4:
					push_error("❌ HAS_SPECIES_STAT requires: species, stat, amount.")
					return

				var species_id: String = parts[1]
				var stat_key: String = parts[2]
				var required: int = parts[3].to_int()
				var result: bool = false
				if GameState.player_statistics != null:
					result = GameState.player_statistics.get_species_stat(StringName(species_id), stat_key) >= required
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
				"knowledge":
					GameState.set_flag(GameState.knowledge_flags, flag_name)
				"sex":
					GameState.set_flag(GameState.sex_flags, flag_name)
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
			GameState.clear_flag(GameState.knowledge_flags, flag_name)
			GameState.clear_flag(GameState.sex_flags, flag_name)


func _filter_choice_options(options: Array) -> Array:
	var visible: Array = []
	for option in options:
		if typeof(option) != TYPE_DICTIONARY:
			continue

		var opt: Dictionary = option
		var is_visible: bool = true

		if opt.has("show_if"):
			is_visible = is_visible and _evaluate_option_condition(opt["show_if"])

		if opt.has("hide_if"):
			var hide_cond: Variant = opt["hide_if"]
			if typeof(hide_cond) == TYPE_STRING and hide_cond == "picked":
				var next_id: String = opt.get("next", "")
				if not next_id.is_empty() and GameState.dialog_flags.get("_picked_" + next_id, false):
					is_visible = false
			else:
				is_visible = is_visible and not _evaluate_option_condition(hide_cond)

		if is_visible:
			visible.append(opt)

	return visible


func _evaluate_option_condition(condition: Variant) -> bool:
	if typeof(condition) == TYPE_STRING:
		return _evaluate_condition_atom(condition)

	if typeof(condition) != TYPE_DICTIONARY:
		return false

	var dict: Dictionary = condition

	# all_of: every nested condition must pass
	if dict.has("all_of") and typeof(dict["all_of"]) == TYPE_ARRAY:
		for nested in dict["all_of"]:
			if not _evaluate_option_condition(nested):
				return false

	# any_of: at least one nested condition must pass
	if dict.has("any_of") and typeof(dict["any_of"]) == TYPE_ARRAY:
		var any_match := false
		for nested in dict["any_of"]:
			if _evaluate_option_condition(nested):
				any_match = true
				break
		if not any_match:
			return false

	for key in dict.keys():
		if key == "all_of" or key == "any_of":
			continue
		if not _evaluate_condition_key_value(str(key), dict[key]):
			return false

	return true


func _evaluate_condition_key_value(key: String, value: Variant) -> bool:
	match key:
		"player_gender":
			return str(GameState.player_gender).to_lower() == str(value).to_lower()
		"has_flag":
			return _all_flags_set(_to_string_array(value))
		"has_any_flag":
			return _any_flag_set(_to_string_array(value))
		"has_item":
			return _has_all_items(_to_string_array(value))
		"has_any_item":
			return _has_any_item(_to_string_array(value))
		"has_item_count":
			return _check_item_count(value)
		"content_disabled":
			# True if the player has opted out of this content category.
			# Usage: "hide_if": { "content_disabled": "feral" }
			return GameState.content_settings.get(str(value), false)
		"min_reputation":
			# True if the player meets the minimum reputation with an NPC.
			# Usage: "show_if": { "min_reputation": { "npc": "nautinto", "amount": 10 } }
			if typeof(value) != TYPE_DICTIONARY:
				push_warning("⚠️ min_reputation expects a dictionary with 'npc' and 'amount'.")
				return false
			var npc_id: String = str(value.get("npc", ""))
			var required: int = int(value.get("amount", 0))
			return GameState.get_reputation(npc_id) >= required
		"min_flirt":
			# True if the player meets the minimum flirt level with an NPC.
			# Usage: "show_if": { "min_flirt": { "npc": "nautinto", "amount": 10 } }
			if typeof(value) != TYPE_DICTIONARY:
				push_warning("⚠️ min_flirt expects a dictionary with 'npc' and 'amount'.")
				return false
			var npc_id: String = str(value.get("npc", ""))
			var required: int = int(value.get("amount", 0))
			return GameState.get_flirt(npc_id) >= required
		"min_species_stat":
			# True if a species stat meets a minimum value.
			# Stat can be: "sex", "wins", "losses", "met"
			# Usage: "show_if": { "min_species_stat": { "species": "meehp", "stat": "sex", "amount": 1 } }
			if typeof(value) != TYPE_DICTIONARY:
				push_warning("⚠️ min_species_stat expects a dictionary with 'species', 'stat', and 'amount'.")
				return false
			var species_id: String = str(value.get("species", ""))
			var stat_key: String = str(value.get("stat", "sex"))
			var required: int = int(value.get("amount", 1))
			if GameState.player_statistics == null:
				return false
			return GameState.player_statistics.get_species_stat(StringName(species_id), stat_key) >= required
		"ability_tier":
			# True if the named ability is assigned to the given tier. No roll happens.
			# Usage: "show_if": { "ability_tier": { "body": "high" } }
			# Multiple entries are AND-ed: all must match.
			if typeof(value) != TYPE_DICTIONARY:
				push_warning("⚠️ ability_tier expects a dictionary, e.g. { \"body\": \"high\" }")
				return false
			for ability in value.keys():
				if not AbilitySystem.is_tier(str(ability), str(value[ability])):
					return false
			return true
		_:
			push_warning("⚠️ Unknown choice condition key: %s" % key)
			return false


func _evaluate_condition_atom(atom: String) -> bool:
	# Optional shorthand support, examples:
	# "show_if.has_item Misc/rope"
	# "has_flag no_beast_sex"
	# "player_gender male"
	var normalized: String = atom.strip_edges()
	if normalized.begins_with("show_if."):
		normalized = normalized.trim_prefix("show_if.")
	if normalized.begins_with("hide_if."):
		normalized = normalized.trim_prefix("hide_if.")

	var parts: PackedStringArray = normalized.split(" ", false)
	if parts.size() < 2:
		return false

	var key: String = parts[0]
	var raw_value: String = " ".join(parts.slice(1))
	return _evaluate_condition_key_value(key, raw_value)


func _to_string_array(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(value) == TYPE_STRING:
		out.append(value)
	elif typeof(value) == TYPE_ARRAY:
		for v in value:
			if typeof(v) == TYPE_STRING:
				out.append(v)
	return out


func _all_flags_set(flags_to_check: Array[String]) -> bool:
	if flags_to_check.is_empty():
		return false

	for flag_name in flags_to_check:
		if not (
			GameState.quest_flags.get(flag_name, false)
			or GameState.dialog_flags.get(flag_name, false)
			or GameState.event_flags.get(flag_name, false)
			or GameState.knowledge_flags.get(flag_name, false)
			or GameState.sex_flags.get(flag_name, false)
			or GameState.temp_flags.get(flag_name, false)
		):
			return false
	return true


func _any_flag_set(flags_to_check: Array[String]) -> bool:
	for flag_name in flags_to_check:
		if (
			GameState.quest_flags.get(flag_name, false)
			or GameState.dialog_flags.get(flag_name, false)
			or GameState.event_flags.get(flag_name, false)
			or GameState.knowledge_flags.get(flag_name, false)
			or GameState.sex_flags.get(flag_name, false)
			or GameState.temp_flags.get(flag_name, false)
		):
			return true
	return false


func _has_all_items(item_paths: Array[String]) -> bool:
	if item_paths.is_empty():
		return false

	for item_path in item_paths:
		if not _has_item_by_key(item_path):
			return false
	return true


func _has_any_item(item_paths: Array[String]) -> bool:
	for item_path in item_paths:
		if _has_item_by_key(item_path):
			return true
	return false


func _check_item_count(value: Variant) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		push_warning("⚠️ has_item_count expects a dictionary: { item, amount, op }")
		return false

	var item_key: String = str(value.get("item", ""))
	var amount: int = int(value.get("amount", 1))
	var op: String = str(value.get("op", ">="))

	var item: InventoryItem = null
	if item_key.begins_with("res://"):
		item = load(item_key) as InventoryItem
	else:
		item = load("res://Resources/Items/%s.tres" % item_key) as InventoryItem

	if item == null:
		push_warning("⚠️ has_item_count: could not load item: %s" % item_key)
		return false

	var count: int = GameState.get_item_count(item)

	match op:
		">=": return count >= amount
		"<=": return count <= amount
		"==": return count == amount
		">":  return count > amount
		"<":  return count < amount
		_:
			push_warning("⚠️ has_item_count: unknown op '%s', defaulting to >=" % op)
			return count >= amount


func _has_item_by_key(item_key: String) -> bool:
	var item: InventoryItem = null
	if item_key.begins_with("res://"):
		item = load(item_key) as InventoryItem
	else:
		item = load("res://Resources/Items/%s.tres" % item_key) as InventoryItem

	if item == null:
		push_warning("⚠️ Could not load InventoryItem for choice condition: %s" % item_key)
		return false

	return GameState.has_item(item)


func choose(index: int) -> void:
	if current_choice_entry.is_empty():
		return

	clear_dialog()

	var chosen_option: Dictionary = current_choice_entry.options[index]
	if chosen_option.get("hide_if") is String and chosen_option.get("hide_if") == "picked":
		var picked_id: String = chosen_option.get("next", "")
		if not picked_id.is_empty():
			GameState.set_flag(GameState.dialog_flags, "_picked_" + picked_id)

	current_choice_entry = {}

	# If the option carries a hidden ability check, roll and branch — no "next" needed.
	if chosen_option.has("check"):
		_resolve_ability_check(chosen_option)
		return

	var next_id: String = chosen_option.get("next", "")
	var next_index: int = _find_entry_index_by_id(next_id)
	if next_index == -1:
		push_error("❌ Next ID not found in dialogue.")
		return

	current_index = next_index
	show_next_line()


## Performs a hidden d20 ability check for a choice option and routes to the result node.
func _resolve_ability_check(option: Dictionary) -> void:
	var check: Dictionary = option.get("check", {})
	var ability: String  = AbilitySystem.resolve_ability(str(check.get("ability", "body")))
	var dc: int          = int(check.get("dc", 10))
	var bonus_parts: Array = []
	var bonus: int       = _evaluate_bonus_if(option.get("bonus_if", []), bonus_parts)
	var result: Dictionary = AbilitySystem.perform_check(ability, dc, bonus)
	_record_and_print_roll(ability, dc, bonus, bonus_parts, result)

	var target_id: String = ""
	if result["nat_20"] and option.has("on_nat20"):
		target_id = str(option["on_nat20"])
	elif result["success"]:
		target_id = str(option.get("on_success", ""))
	else:
		target_id = str(option.get("on_fail", ""))

	if target_id.is_empty():
		push_error("❌ Ability check: no routing target (on_success/on_fail missing).")
		return

	var next_index: int = _find_entry_index_by_id(target_id)
	if next_index == -1:
		push_error("❌ Ability check: target ID not found: %s" % target_id)
		return

	current_index = next_index
	show_next_line()


## Sums all bonus_if bonuses whose condition is currently met.
## Each entry: { "has_item": "path" OR "has_flag": "name", "bonus": int }
## out_parts (optional) is filled with human-readable strings for each applied bonus.
func _evaluate_bonus_if(bonus_if: Array, out_parts: Array = []) -> int:
	var total: int = 0
	for entry in bonus_if:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var bonus: int = int(entry.get("bonus", 0))
		if entry.has("has_item") and _has_item_by_key(str(entry["has_item"])):
			total += bonus
			out_parts.append("+%d (%s item)" % [bonus, str(entry["has_item"])])
		elif entry.has("has_flag") and _all_flags_set([str(entry["has_flag"])]):
			total += bonus
			out_parts.append("+%d (%s flag)" % [bonus, str(entry["has_flag"])])
	return total


## Processes a standalone "type": "check" node — rolls immediately, no player input.
func _resolve_standalone_check(entry: Dictionary) -> void:
	var ability: String  = AbilitySystem.resolve_ability(str(entry.get("ability", "body")))
	var dc: int          = int(entry.get("dc", 10))
	var bonus_parts: Array = []
	var bonus: int       = _evaluate_bonus_if(entry.get("bonus_if", []), bonus_parts)
	var result: Dictionary = AbilitySystem.perform_check(ability, dc, bonus)
	_record_and_print_roll(ability, dc, bonus, bonus_parts, result)

	apply_flags(entry)

	var target_id: String = ""
	if result["nat_20"] and entry.has("on_nat20"):
		target_id = str(entry["on_nat20"])
	elif result["success"]:
		target_id = str(entry.get("on_success", ""))
	else:
		target_id = str(entry.get("on_fail", ""))

	if target_id.is_empty():
		push_error("❌ Standalone check: no routing target (on_success/on_fail missing).")
		return

	var next_index: int = _find_entry_index_by_id(target_id)
	if next_index == -1:
		push_error("❌ Standalone check: target ID not found: %s" % target_id)
		return

	current_index = next_index
	show_next_line()

## Records the roll breakdown to AbilitySystem.last_roll and prints it to console.
func _record_and_print_roll(ability: String, dc: int, bonus: int, bonus_parts: Array, result: Dictionary) -> void:
	var is_flat: bool = ability == "flat"
	var score: int   = 0 if is_flat else AbilitySystem.get_score(ability)
	var tier: String = "flat" if is_flat else AbilitySystem.get_tier(ability)
	AbilitySystem.last_roll = {
		"ability":     ability,
		"tier":        tier,
		"score":       score,
		"roll":        result["roll"],
		"bonus":       bonus,
		"bonus_parts": bonus_parts.duplicate(),
		"total":       result["total"],
		"dc":          dc,
		"success":     result["success"],
		"nat_20":      result["nat_20"],
	}
	var outcome: String = "NAT 20!" if result["nat_20"] else ("HIT" if result["success"] else "MISS")
	print("🎲 CHECK [%s/%s] d20:%d + score:%d + bonus:%d = %d vs DC%d → %s" % [
		ability.to_upper(), tier.to_upper(),
		result["roll"], score, bonus, result["total"], dc, outcome,
	])
	if not bonus_parts.is_empty():
		print("   Bonuses: %s" % ", ".join(bonus_parts))


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
