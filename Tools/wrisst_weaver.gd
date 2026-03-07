extends Control

# --- CONFIGURATION ---
const SAVE_DIR = "res://Narrative/"
const MUSIC_DIR = "res://Audio/Music/"
const AMBIENCE_DIR = "res://Audio/Ambience/"
const AUDIO_EXTENSIONS = ["ogg", "mp3", "wav", "flac"]
const CONDITION_OPERATORS = ["none", "has_flag", "has_any_flag", "player_gender", "has_item", "has_any_item"]

# Map your command logic here for auto-complete/UI generation
const COMMAND_TEMPLATES = {
	"Show Portrait": "@SHOW_PORTRAIT base",
	"Hide Portrait": "@HIDE_PORTRAIT",
	"Show Extra": "@SHOW_EXTRA base",
	"Hide Extra": "@HIDE_EXTRA",
	"Show Scene (Slide)": "@SHOW_SCENE debug_01",
	"Hide Scene": "@HIDE_SCENE",
	"Show Zone": "@SHOW_ZONE Klyftet/",
	"Play Music": "@PLAY_MUSIC res://Audio/Music/",
	"Music Clip": "@MUSIC_CLIP 1",
	"Stop Music": "@STOP_MUSIC",
	"Fade Music Out": "@FADE_MUSIC_OUT",
	"Play Ambience": "@PLAY_AMBIENCE wind res://Audio/Ambience/",
	"Stop Ambience": "@STOP_AMBIENCE wind",
	"Stop All Ambience": "@STOP_ALL_AMBIENCE",
	"Start Combat": "@START_COMBAT",
	"Leave Encounter": "@LEAVE_ENCOUNTER",
	"Add Ore": "@ADD_ORE 10",
	"Remove Ore": "@REMOVE_ORE 10",
	"Add Crowns": "@ADD_CROWNS 1",
	"Remove Crowns": "@REMOVE_CROWNS 1",
	"Add Drots": "@ADD_DROTS 1",
	"Remove Drots": "@REMOVE_DROTS 1",
	"Add Item": "@ADD_ITEM item_id",
	"Remove Item": "@REMOVE_ITEM item_id",
	"Add Reputation": "@ADD_REPUTATION minttärä 10",
	"Remove Reputation": "@REMOVE_REPUTATION minttärä 10",
	"Set Scene From": "@SET_SCENE_FROM",
	"Location Change": "@LOCATION_CHANGE area_key",
	"Change Location": "@CHANGE_LOCATION area_key"
}

@onready var graph_edit = $GraphEdit
@onready var file_dialog = $FileDialog

# Context menu vars
var context_menu: PopupMenu
var context_menu_position: Vector2 = Vector2.ZERO

func _collect_audio_paths_recursive(base_dir: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(base_dir)
	if dir == null:
		return results

	dir.list_dir_begin()
	var item_name := dir.get_next()
	while item_name != "":
		if item_name.begins_with("."):
			item_name = dir.get_next()
			continue

		var full_path := base_dir.path_join(item_name)
		if dir.current_is_dir():
			results.append_array(_collect_audio_paths_recursive(full_path))
		else:
			var ext := item_name.get_extension().to_lower()
			if AUDIO_EXTENSIONS.has(ext):
				results.append(full_path)

		item_name = dir.get_next()

	dir.list_dir_end()
	results.sort()
	return results


func _populate_audio_picker(picker: OptionButton, base_dir: String) -> void:
	picker.clear()
	var paths := _collect_audio_paths_recursive(base_dir)
	if paths.is_empty():
		picker.add_item("<No audio files found>")
		picker.set_item_disabled(0, true)
		return

	for path in paths:
		var display := path.trim_prefix(base_dir)
		picker.add_item(display)
		picker.set_item_metadata(picker.item_count - 1, path)


func _get_picker_audio_path(picker: OptionButton) -> String:
	if picker.item_count == 0:
		return ""
	var selected := picker.selected
	if selected < 0:
		selected = 0
	if picker.get_item_metadata(selected) != null:
		return str(picker.get_item_metadata(selected))
	return picker.get_item_text(selected)


func _select_audio_path_in_picker(picker: OptionButton, path: String) -> void:
	if path == "":
		return
	for i in range(picker.item_count):
		if str(picker.get_item_metadata(i)) == path or picker.get_item_text(i) == path:
			picker.select(i)
			return

	# Keep compatibility with existing commands that point outside normal folders.
	picker.add_item("[Custom] " + path)
	picker.set_item_metadata(picker.item_count - 1, path)
	picker.select(picker.item_count - 1)


func _build_play_music_command(path: String) -> String:
	return "@PLAY_MUSIC %s" % path


func _build_music_clip_command(clip_value: String) -> String:
	var clean_clip := clip_value.strip_edges()
	if clean_clip == "":
		clean_clip = "1"
	return "@MUSIC_CLIP %s" % clean_clip


func _build_play_ambience_command(tag: String, path: String) -> String:
	var clean_tag := tag.strip_edges()
	if clean_tag == "":
		clean_tag = "wind"
	return "@PLAY_AMBIENCE %s %s" % [clean_tag, path]


func _extract_play_music_path(command_text: String) -> String:
	var parts: PackedStringArray = command_text.split(" ", false)
	if parts.size() < 2:
		return ""
	return parts[1]


func _extract_play_ambience_parts(command_text: String) -> Dictionary:
	var parts: PackedStringArray = command_text.split(" ", false)
	if parts.size() < 3:
		return {"tag": "wind", "path": ""}
	return {
		"tag": parts[1],
		"path": parts[2]
	}


func _extract_music_clip_value(command_text: String) -> String:
	var parts: PackedStringArray = command_text.split(" ", false)
	if parts.size() < 2:
		return "1"
	return parts[1]


func _get_choice_option_rows(node: GraphNode) -> Array:
	var rows: Array = []
	for child in node.get_children():
		if child is HBoxContainer and child.has_meta("choice_option_row"):
			rows.append(child)
	return rows


func _create_condition_operator_option(name: String) -> OptionButton:
	var opt := OptionButton.new()
	opt.name = name
	for key in CONDITION_OPERATORS:
		opt.add_item(key)
	opt.select(0)
	return opt


func _set_operator_selection(operator_opt: OptionButton, operator_key: String) -> void:
	for i in range(operator_opt.item_count):
		if operator_opt.get_item_text(i) == operator_key:
			operator_opt.select(i)
			return
	operator_opt.select(0)


func _fill_condition_controls_from_value(operator_opt: OptionButton, value_edit: LineEdit, condition_value: Variant) -> void:
	if condition_value == null:
		_set_operator_selection(operator_opt, "none")
		value_edit.text = ""
		return

	if typeof(condition_value) == TYPE_STRING:
		# Legacy shorthand support.
		var parsed = _parse_condition_text(condition_value)
		if typeof(parsed) != TYPE_STRING:
			_fill_condition_controls_from_value(operator_opt, value_edit, parsed)
			return
		_set_operator_selection(operator_opt, "none")
		value_edit.text = str(condition_value)
		return

	if typeof(condition_value) != TYPE_DICTIONARY:
		_set_operator_selection(operator_opt, "none")
		value_edit.text = ""
		return

	var dict: Dictionary = condition_value
	for key in CONDITION_OPERATORS:
		if key == "none":
			continue
		if dict.has(key):
			_set_operator_selection(operator_opt, key)
			var raw_value: Variant = dict[key]
			if typeof(raw_value) == TYPE_ARRAY:
				value_edit.text = ", ".join(raw_value)
			else:
				value_edit.text = str(raw_value)
			return

	# Fallback for complex dicts we can't map directly.
	_set_operator_selection(operator_opt, "none")
	value_edit.text = JSON.stringify(dict)


func _build_condition_from_controls(operator_opt: OptionButton, value_edit: LineEdit) -> Variant:
	var selected_operator: String = operator_opt.get_item_text(operator_opt.selected)
	var raw_value: String = value_edit.text.strip_edges()

	if selected_operator == "none":
		if raw_value == "":
			return null
		# Preserve legacy/advanced manual expressions when operator is left at none.
		return _parse_condition_text(raw_value)

	if raw_value == "":
		return null

	if selected_operator == "player_gender":
		return { selected_operator: raw_value.to_lower() }

	if selected_operator == "has_flag" or selected_operator == "has_any_flag" or selected_operator == "has_item" or selected_operator == "has_any_item":
		var parts: Array[String] = []
		for token in raw_value.split(","):
			var clean: String = token.strip_edges()
			if clean != "":
				parts.append(clean)

		if parts.is_empty():
			return null

		if selected_operator == "has_flag" or selected_operator == "has_item":
			return { selected_operator: parts[0] if parts.size() == 1 else parts }

		# any variants should always be arrays
		return { selected_operator: parts }

	return { selected_operator: raw_value }


func _add_choice_option_row(node: GraphNode, option_data: Dictionary = {}):
	var idx = node.get_child_count()
	var row = HBoxContainer.new()
	row.set_meta("choice_option_row", true)

	var text_edit = LineEdit.new()
	text_edit.name = "OptionText"
	text_edit.placeholder_text = "Option text"
	text_edit.text = str(option_data.get("text", ""))
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var show_if_opt = _create_condition_operator_option("ShowIf_Operator")
	show_if_opt.tooltip_text = "Show option only if this condition passes"
	var show_if_edit = LineEdit.new()
	show_if_edit.name = "ShowIf_Value"
	show_if_edit.placeholder_text = "Value (or comma list for flags/items)"
	show_if_edit.custom_minimum_size.x = 180

	var hide_if_opt = _create_condition_operator_option("HideIf_Operator")
	hide_if_opt.tooltip_text = "Hide option if this condition passes"
	var hide_if_edit = LineEdit.new()
	hide_if_edit.name = "HideIf_Value"
	hide_if_edit.placeholder_text = "Value (or comma list for flags/items)"
	hide_if_edit.custom_minimum_size.x = 180

	if option_data.has("show_if"):
		_fill_condition_controls_from_value(show_if_opt, show_if_edit, option_data["show_if"])
	if option_data.has("hide_if"):
		_fill_condition_controls_from_value(hide_if_opt, hide_if_edit, option_data["hide_if"])

	var remove_btn = Button.new()
	remove_btn.text = "-"
	remove_btn.tooltip_text = "Remove this option"
	remove_btn.pressed.connect(func():
		row.queue_free()
	)

	row.add_child(text_edit)
	row.add_child(show_if_opt)
	row.add_child(show_if_edit)
	row.add_child(hide_if_opt)
	row.add_child(hide_if_edit)
	row.add_child(remove_btn)

	node.add_child(row)
	node.set_slot(idx, false, 0, Color.WHITE, true, 0, Color.WHITE)


func _parse_condition_text(raw_text: String) -> Variant:
	var trimmed := raw_text.strip_edges()
	if trimmed == "":
		return null

	if (trimmed.begins_with("{") and trimmed.ends_with("}")) or (trimmed.begins_with("[") and trimmed.ends_with("]")):
		var parsed = JSON.parse_string(trimmed)
		if parsed != null:
			return parsed

	return trimmed


func _collect_known_flags(export_array: Array) -> Dictionary:
	var known: Dictionary = {}
	for entry in export_array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.has("set_flag"):
			var sf = entry["set_flag"]
			if typeof(sf) == TYPE_STRING:
				known[sf] = true
			elif typeof(sf) == TYPE_ARRAY:
				for f in sf:
					if typeof(f) == TYPE_STRING:
						known[f] = true
	return known


func _validate_export_array(export_array: Array) -> void:
	var ids_seen: Dictionary = {}
	for entry in export_array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var entry_id: String = str(entry.get("id", "")).strip_edges()
		if entry_id == "":
			push_warning("⚠️ Weaver validation: Found entry with empty id.")
		elif ids_seen.has(entry_id):
			push_warning("⚠️ Weaver validation: Duplicate id: %s" % entry_id)
		else:
			ids_seen[entry_id] = true

		if entry.get("type", "") == "command":
			var cmd: String = str(entry.get("command", "")).strip_edges()
			if cmd != "" and not cmd.begins_with("@"):
				push_warning("⚠️ Weaver validation: Command entry '%s' does not start with '@'." % entry_id)

	var known_flags := _collect_known_flags(export_array)
	for entry in export_array:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		if entry.get("type", "") != "choice":
			continue
		for option in entry.get("options", []):
			if typeof(option) != TYPE_DICTIONARY:
				continue
			for cond_key in ["show_if", "hide_if"]:
				if not option.has(cond_key):
					continue
				var cond_val = option[cond_key]
				if typeof(cond_val) != TYPE_DICTIONARY:
					continue
				for flag_key in ["has_flag", "has_any_flag"]:
					if not cond_val.has(flag_key):
						continue
					var flags: Array[String] = []
					if typeof(cond_val[flag_key]) == TYPE_STRING:
						flags.append(cond_val[flag_key])
					elif typeof(cond_val[flag_key]) == TYPE_ARRAY:
						for f in cond_val[flag_key]:
							if typeof(f) == TYPE_STRING:
								flags.append(f)
					for f in flags:
						if not known_flags.has(f):
							push_warning("⚠️ Weaver validation: Choice condition references unknown flag '%s'." % f)

func _ready():
	# UI Connections
	$SaveButton.pressed.connect(_on_save_pressed)
	$LoadButton.pressed.connect(_on_load_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	# Graph Logic
	graph_edit.popup_request.connect(_on_popup_request)
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	
	# Create Right-Click Menu
	context_menu = PopupMenu.new()
	context_menu.name = "ContextMenu"
	context_menu.add_item("Narration / NPC Node", 0)
	context_menu.add_item("Choice Node", 1)
	context_menu.add_item("Command Node", 2)
	context_menu.add_separator()
	context_menu.add_item("Logic: Check Flag (Boolean)", 3)
	context_menu.add_item("Logic: Condition (Stat/Money)", 4)
	context_menu.add_item("Logic: Multi-Flag (Switch)", 5)
	
	context_menu.id_pressed.connect(_on_context_menu_item_selected)
	add_child(context_menu)

# --- CONTEXT MENU LOGIC ---

func _on_popup_request(at_position):
	context_menu_position = at_position
	context_menu.position = Vector2(get_viewport().get_mouse_position())
	context_menu.popup()

func _on_context_menu_item_selected(id):
	var spawn_pos = (context_menu_position + graph_edit.scroll_offset) / graph_edit.zoom
	create_node(id, spawn_pos)

# --- NODE CREATION FACTORY ---

func create_node(type_id: int, position_offset: Vector2, data: Dictionary = {}):
	var node = GraphNode.new()
	node.position_offset = position_offset
	node.resizable = true
	
	# Metadata to track what kind of JSON object this is
	node.set_meta("node_type", type_id) 

	# --- HEADER (ID + DELETE) ---
	# This creates a custom header because Godot 4 removed the built-in close button logic
	var id_box = HBoxContainer.new()
	
	var id_label = Label.new()
	id_label.text = "ID:"
	
	var id_edit = LineEdit.new()
	id_edit.name = "ID_Edit"
	id_edit.text = data.get("id", "node_" + str(randi() % 1000))
	id_edit.custom_minimum_size.x = 120
	id_edit.expand_to_text_length = true
	
	var del_btn = Button.new()
	del_btn.text = " X "
	del_btn.modulate = Color(1, 0.4, 0.4)
	del_btn.pressed.connect(func():
		# Safely remove connections before deleting node
		var node_name = node.name
		for conn in graph_edit.get_connection_list():
			if conn.from_node == node_name or conn.to_node == node_name:
				graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
		node.queue_free()
	)
	
	id_box.add_child(id_label)
	id_box.add_child(id_edit)
	id_box.add_child(del_btn)
	
	node.add_child(id_box) # Child Index 0

	# --- NODE SPECIFIC CONTENT ---
	match type_id:
		0: # NARRATION
			node.title = "Narration / NPC"
			node.self_modulate = Color("e0cda6") # Beige
			
			# Input on Header (Slot 0)
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var name_edit = LineEdit.new() # Child 1
			name_edit.placeholder_text = "Speaker (Empty = Narrator)"
			name_edit.name = "Speaker_Edit"
			name_edit.text = data.get("name", "")
			node.add_child(name_edit)
			
			var text_edit = TextEdit.new() # Child 2
			text_edit.name = "Text_Edit"
			text_edit.text = data.get("text", "")
			text_edit.custom_minimum_size.y = 100
			text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
			text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			node.add_child(text_edit)
			
			# Flag Setting Container
			var flag_box = HBoxContainer.new() # Child 3
			var flag_edit = LineEdit.new()
			flag_edit.name = "SetFlag_Edit"
			flag_edit.placeholder_text = "Set Flag (e.g. met_mint)"
			var set_flag_raw: Variant = data.get("set_flag", "")
			if typeof(set_flag_raw) == TYPE_ARRAY:
				flag_edit.text = ", ".join(set_flag_raw)
			else:
				flag_edit.text = str(set_flag_raw)
			flag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var flag_type_opt = OptionButton.new()
			flag_type_opt.name = "FlagType_Opt"
			flag_type_opt.tooltip_text = "Target flag dictionary"
			flag_type_opt.add_item("quest")
			flag_type_opt.add_item("dialog")
			flag_type_opt.add_item("event")
			flag_type_opt.add_item("knowledge")
			flag_type_opt.add_item("sex")
			flag_type_opt.add_item("temp")
			var desired_flag_type: String = str(data.get("flag_type", "quest"))
			for i in range(flag_type_opt.item_count):
				if flag_type_opt.get_item_text(i) == desired_flag_type:
					flag_type_opt.select(i)
					break
			
			flag_box.add_child(flag_edit)
			flag_box.add_child(flag_type_opt)
			node.add_child(flag_box)
			
			# Output on Flag Box (Child 3)
			node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.WHITE)
			
		1: # CHOICE
			node.title = "Player Choice"
			node.self_modulate = Color("ffcf33") # Vibrant Gold
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var add_btn = Button.new() # Child 1
			add_btn.text = "+ Add Option"
			add_btn.pressed.connect(func(): _add_choice_option_row(node, {}))
			node.add_child(add_btn)
			
			# Load Options
			if data.has("options"):
				for opt in data.options:
					_add_choice_option_row(node, opt)
			else:
				_add_choice_option_row(node, {})
				
		2: # COMMAND
			node.title = "Command / Event"
			node.self_modulate = Color("8fc7d4") # Vibrant Cyan-Grey
			node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
			
			var cmd_list = OptionButton.new() # Child 1
			cmd_list.name = "Cmd_Selector"
			for key in COMMAND_TEMPLATES.keys():
				cmd_list.add_item(key)
			if cmd_list.item_count > 0:
				cmd_list.select(0)
			node.add_child(cmd_list)
			
			var cmd_edit = LineEdit.new() # Child 2
			cmd_edit.name = "Command_Edit"
			cmd_edit.custom_minimum_size.x = 250
			cmd_edit.text = data.get("command", "")
			node.add_child(cmd_edit)
			
			# Clear Flags Logic
			var clear_edit = LineEdit.new() # Child 3
			clear_edit.name = "ClearFlag_Edit"
			clear_edit.placeholder_text = "Clear Flags (comma sep)"
			if data.has("clear_flag"):
				var c_arr = data.get("clear_flag", [])
				clear_edit.text = ", ".join(c_arr)
			node.add_child(clear_edit)
			
			# Output on ClearFlag (Child 3)
			node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.WHITE)

			var clear_chk = CheckBox.new() # Child 4
			clear_chk.name = "Clear_Chk"
			clear_chk.text = "Clear existing text?"
			clear_chk.button_pressed = bool(data.get("clear", false))
			node.add_child(clear_chk)

			var music_picker = OptionButton.new() # Child 5
			music_picker.name = "MusicPicker"
			node.add_child(music_picker)
			_populate_audio_picker(music_picker, MUSIC_DIR)

			var ambience_picker = OptionButton.new() # Child 6
			ambience_picker.name = "AmbiencePicker"
			node.add_child(ambience_picker)
			_populate_audio_picker(ambience_picker, AMBIENCE_DIR)

			var ambience_tag_edit = LineEdit.new() # Child 7
			ambience_tag_edit.name = "AmbienceTag_Edit"
			ambience_tag_edit.placeholder_text = "Ambience tag (e.g. wind)"
			ambience_tag_edit.text = "wind"
			node.add_child(ambience_tag_edit)

			var clip_edit = LineEdit.new() # Child 8
			clip_edit.name = "MusicClip_Edit"
			clip_edit.placeholder_text = "Clip index/name"
			clip_edit.text = "1"
			node.add_child(clip_edit)

			var update_command_ui = func():
				var selected_key = cmd_list.get_item_text(cmd_list.selected)
				var is_music = selected_key == "Play Music"
				var is_music_clip = selected_key == "Music Clip"
				var is_ambience = selected_key == "Play Ambience"
				music_picker.visible = is_music
				clip_edit.visible = is_music_clip
				ambience_picker.visible = is_ambience
				ambience_tag_edit.visible = is_ambience

			var update_command_text_from_inputs = func():
				var selected_key = cmd_list.get_item_text(cmd_list.selected)
				if selected_key == "Play Music":
					var music_path = _get_picker_audio_path(music_picker)
					if music_path != "":
						cmd_edit.text = _build_play_music_command(music_path)
				elif selected_key == "Music Clip":
					cmd_edit.text = _build_music_clip_command(clip_edit.text)
				elif selected_key == "Play Ambience":
					var ambience_path = _get_picker_audio_path(ambience_picker)
					if ambience_path != "":
						cmd_edit.text = _build_play_ambience_command(ambience_tag_edit.text, ambience_path)

			cmd_list.item_selected.connect(func(idx):
				var key = cmd_list.get_item_text(idx)
				if key == "Play Music" or key == "Play Ambience":
					update_command_text_from_inputs.call()
				else:
					cmd_edit.text = COMMAND_TEMPLATES[key]
				update_command_ui.call()
			)

			music_picker.item_selected.connect(func(_idx):
				update_command_text_from_inputs.call()
			)

			ambience_picker.item_selected.connect(func(_idx):
				update_command_text_from_inputs.call()
			)

			ambience_tag_edit.text_changed.connect(func(_new_text):
				update_command_text_from_inputs.call()
			)

			clip_edit.text_changed.connect(func(_new_text):
				update_command_text_from_inputs.call()
			)

			# If loading an existing command, restore picker state.
			if cmd_edit.text.begins_with("@PLAY_MUSIC "):
				for i in range(cmd_list.item_count):
					if cmd_list.get_item_text(i) == "Play Music":
						cmd_list.select(i)
						break
				_select_audio_path_in_picker(music_picker, _extract_play_music_path(cmd_edit.text))
			elif cmd_edit.text.begins_with("@PLAY_AMBIENCE "):
				for i in range(cmd_list.item_count):
					if cmd_list.get_item_text(i) == "Play Ambience":
						cmd_list.select(i)
						break
				var ambience_parts = _extract_play_ambience_parts(cmd_edit.text)
				ambience_tag_edit.text = ambience_parts.get("tag", "wind")
				_select_audio_path_in_picker(ambience_picker, ambience_parts.get("path", ""))
			elif cmd_edit.text.begins_with("@MUSIC_CLIP "):
				for i in range(cmd_list.item_count):
					if cmd_list.get_item_text(i) == "Music Clip":
						cmd_list.select(i)
						break
				clip_edit.text = _extract_music_clip_value(cmd_edit.text)

			update_command_ui.call()
			if cmd_edit.text == "":
				var selected_idx: int = cmd_list.selected
				if selected_idx < 0 and cmd_list.item_count > 0:
					selected_idx = 0
				if selected_idx >= 0:
					cmd_edit.text = COMMAND_TEMPLATES[cmd_list.get_item_text(selected_idx)]
			
		3: # LOGIC (BOOLEAN)
			node.title = "Check Flag (Boolean)"
			node.self_modulate = Color("4ea9ff") # Vibrant Blue
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var flag_edit = LineEdit.new() # Child 1
			flag_edit.name = "Flag_Edit"
			flag_edit.placeholder_text = "Flag Name"
			if data.has("check_flags"):
				var flags = data.check_flags.get("flags", [])
				if flags.size() > 0: flag_edit.text = flags[0]
			node.add_child(flag_edit)
			
			var l_pass = Label.new(); l_pass.text = "Success"; l_pass.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 2
			node.add_child(l_pass)
			node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)
			
			var l_fail = Label.new(); l_fail.text = "Fail"; l_fail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 3
			node.add_child(l_fail)
			node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.RED)

		4: # LOGIC (CONDITION)
			node.title = "Check Stat/Money"
			node.self_modulate = Color("bda6e0") # Purple
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var type_opt = OptionButton.new() # Child 1
			type_opt.name = "CondType"
			type_opt.add_item("Currency (Ore)")
			type_opt.add_item("Stat")
			node.add_child(type_opt)
			
			var param1 = LineEdit.new() # Child 2
			param1.name = "Param1"
			param1.placeholder_text = "Name (e.g. ore)"
			node.add_child(param1)
			
			var param2 = LineEdit.new() # Child 3
			param2.name = "Param2"
			param2.placeholder_text = "Amount / Value"
			node.add_child(param2)
			
			var param3 = CheckBox.new() # Child 4
			param3.name = "Param3"
			param3.text = "Deduct?"
			node.add_child(param3)
			
			if data.has("condition"):
				if data.condition.has("currency"):
					type_opt.selected = 0
					param1.text = data.condition.currency
					param2.text = str(data.condition.amount)
					param3.button_pressed = data.condition.get("deduct", false)
				elif data.condition.has("stat"):
					type_opt.selected = 1
					param1.text = data.condition.stat
					param2.text = str(data.condition.is)
			
			var l1 = Label.new(); l1.text = "True"; l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 5
			node.add_child(l1)
			node.set_slot(5, false, 0, Color.WHITE, true, 0, Color.GREEN)
			
			var l2 = Label.new(); l2.text = "False"; l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 6
			node.add_child(l2)
			node.set_slot(6, false, 0, Color.WHITE, true, 0, Color.RED)
			
		5: # LOGIC (MULTI)
			node.title = "Check Multi-Flags"
			node.self_modulate = Color("4ea9ff")
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var add_btn = Button.new() # Child 1
			add_btn.text = "+ Add Flag Check"
			add_btn.pressed.connect(func(): _add_dynamic_slot(node, "", true))
			node.add_child(add_btn)
			
			var def_label = Label.new() # Child 2
			def_label.text = "Default (Else)"
			def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			node.add_child(def_label)
			node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.RED)
			
			if data.has("check_temp_flags"):
				var flags = data.check_temp_flags
				for k in flags.keys():
					if k == "default": continue
					_add_dynamic_slot(node, k, true)

	graph_edit.add_child(node)
	return node

func _add_dynamic_slot(node: GraphNode, text: String, is_output: bool):
	var idx = node.get_child_count()
	var edit = LineEdit.new()
	edit.text = text
	edit.placeholder_text = "Value / Option Text..."
	edit.expand_to_text_length = true
	node.add_child(edit)
	node.set_slot(idx, false, 0, Color.WHITE, is_output, 0, Color.WHITE)

# --- CONNECTIONS ---
func _on_connection_request(from, from_slot, to, to_slot):
	graph_edit.connect_node(from, from_slot, to, to_slot)

func _on_disconnection_request(from, from_slot, to, to_slot):
	graph_edit.disconnect_node(from, from_slot, to, to_slot)

# --- EXPORT TO JSON ---
func _on_save_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.filters = ["*.json ; Wrisst Dialogue"]
	file_dialog.popup_centered()

func _on_load_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.json ; Wrisst Dialogue"]
	file_dialog.popup_centered()

func _on_file_selected(path):
	if file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		save_to_json(path)
	else:
		load_from_json(path)

func save_to_json(path):
	var export_array = []
	var nodes = graph_edit.get_children()
	var connections = graph_edit.get_connection_list()
	
	# Helper: Find node ID connected to a specific output port
	var get_target = func(node_name, port_idx):
		for conn in connections:
			if conn.from_node == node_name and conn.from_port == port_idx:
				var target_node = graph_edit.get_node(conn.to_node)
				return target_node.get_node("ID_Edit").text
		return ""

	for node in nodes:
		if not node is GraphNode: continue
		var type_id = node.get_meta("node_type")
		var node_id = node.get_node("ID_Edit").text
		var entry = {}
		entry["id"] = node_id
		
		match type_id:
			0: # Narration
				var spk = node.get_node("Speaker_Edit").text
				entry["type"] = "npc" if spk != "" else "narration"
				if spk != "": entry["name"] = spk
				entry["text"] = node.get_node("Text_Edit").text
				
				var flag_box = node.get_node("HBoxContainer") # SetFlag is in HBox
				var flag_edit = flag_box.get_child(0)
				var flag_opt = flag_box.get_child(1)
				
				if flag_edit.text != "":
					var flag_text: String = str(flag_edit.text).strip_edges()
					if flag_text.find(",") != -1:
						var set_flags: Array = []
						for f in flag_text.split(","):
							var clean_f: String = str(f).strip_edges()
							if clean_f != "":
								set_flags.append(clean_f)
						entry["set_flag"] = set_flags
					else:
						entry["set_flag"] = flag_text
					if flag_opt is OptionButton:
						entry["flag_type"] = (flag_opt as OptionButton).get_item_text((flag_opt as OptionButton).selected)
				
				entry["next"] = get_target.call(node.name, 0) # Port 0 (Slot 3)
				
			1: # Choice
				entry["type"] = "choice"
				entry["options"] = []
				var option_rows = _get_choice_option_rows(node)
				for i in range(option_rows.size()):
					var row: HBoxContainer = option_rows[i]
					var option_text_edit := row.get_node("OptionText") as LineEdit
					var show_if_opt := row.get_node("ShowIf_Operator") as OptionButton
					var show_if_edit := row.get_node("ShowIf_Value") as LineEdit
					var hide_if_opt := row.get_node("HideIf_Operator") as OptionButton
					var hide_if_edit := row.get_node("HideIf_Value") as LineEdit

					var option_entry := {
						"text": option_text_edit.text,
						"next": get_target.call(node.name, i)
					}

					var show_if_value = _build_condition_from_controls(show_if_opt, show_if_edit)
					if show_if_value != null:
						option_entry["show_if"] = show_if_value

					var hide_if_value = _build_condition_from_controls(hide_if_opt, hide_if_edit)
					if hide_if_value != null:
						option_entry["hide_if"] = hide_if_value

					entry["options"].append(option_entry)
						
			2: # Command
				entry["type"] = "command"
				entry["command"] = node.get_node("Command_Edit").text
				entry["clear"] = (node.get_node("Clear_Chk") as CheckBox).button_pressed
				
				var clear_txt = node.get_node("ClearFlag_Edit").text
				if clear_txt != "":
					var flags = clear_txt.split(",")
					entry["clear_flag"] = []
					for f in flags: entry["clear_flag"].append(f.strip_edges())
					
				entry["next"] = get_target.call(node.name, 0)
				
			3: # Logic Bool
				entry["type"] = "logic"
				entry["logic_type"] = "check_flags"
				entry["check_flags"] = {
					"flags": [node.get_node("Flag_Edit").text],
					"on_success": get_target.call(node.name, 0),
					"on_fail": get_target.call(node.name, 1)
				}
				
			4: # Logic Condition
				entry["type"] = "logic"
				entry["logic_type"] = "condition"
				var t = node.get_node("CondType").selected
				var p1 = node.get_node("Param1").text
				var p2 = node.get_node("Param2").text
				var p3 = node.get_node("Param3").button_pressed
				
				if t == 0: # Currency
					entry["condition"] = {
						"currency": p1, "amount": float(p2), "deduct": p3,
						"on_success": get_target.call(node.name, 0),
						"on_fail": get_target.call(node.name, 1)
					}
				else: # Stat
					entry["condition"] = {
						"stat": p1, "is": p2,
						"on_success": get_target.call(node.name, 0),
						"on_fail": get_target.call(node.name, 1)
					}
					
			5: # Logic Multi
				entry["type"] = "check_temp_flags_multi"
				entry["check_temp_flags"] = {}
				
				# Default is Child 2 -> Port 0
				entry["check_temp_flags"]["default"] = get_target.call(node.name, 0)
				
				# Dynamic starts Child 3 -> Port 1
				var dyn_start = 3
				for i in range(dyn_start, node.get_child_count()):
					var child = node.get_child(i)
					if child is LineEdit:
						var port = (i - dyn_start) + 1
						entry["check_temp_flags"][child.text] = get_target.call(node.name, port)

		export_array.append(entry)

	_validate_export_array(export_array)
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_array, "\t"))
		print("SUCCESS: Saved Wrisst JSON.")

# --- LOAD FROM JSON ---
func load_from_json(path):
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode: c.queue_free()
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Array: return
		
	var nodes_by_id = {}
	var pos = Vector2(50, 50)
	
	# 1. Spawn Nodes
	for entry in data:
		var type = 0
		var t = entry.get("type", "narration")
		if t == "npc": type = 0
		elif t == "choice": type = 1
		elif t == "command": type = 2
		elif t == "check_temp_flags_multi": type = 5
		elif t == "logic":
			var lt = entry.get("logic_type", "")
			if lt == "condition": type = 4
			elif lt == "check_temp_flags_multi": type = 5
			else: type = 3
		
		var node = create_node(type, pos, entry)
		nodes_by_id[entry["id"]] = node
		pos.x += 420
		if pos.x > 2500: 
			pos.x = 50; pos.y += 350
			
	# 2. Connect
	await get_tree().process_frame
	
	for entry in data:
		var node = nodes_by_id.get(entry["id"])
		if not node: continue
		
		var connect_to = func(target_id, from_port):
			if target_id and nodes_by_id.has(target_id):
				graph_edit.connect_node(node.name, from_port, nodes_by_id[target_id].name, 0)
		
		if entry.has("next") and entry["next"] is String:
			connect_to.call(entry["next"], 0)
			
		if entry.get("type") == "choice":
			var opts = entry.get("options", [])
			for i in range(opts.size()):
				connect_to.call(opts[i]["next"], i)

		# Logic reconnects (support both explicit logic_type and legacy shape-only JSON)
		if entry.get("logic_type") == "check_flags" or entry.has("check_flags"):
			connect_to.call(entry.check_flags.get("on_success"), 0)
			connect_to.call(entry.check_flags.get("on_fail"), 1)

		if entry.get("logic_type") == "condition" or entry.has("condition"):
			connect_to.call(entry.condition.get("on_success"), 0)
			connect_to.call(entry.condition.get("on_fail"), 1)
			
		if entry.get("type") == "check_temp_flags_multi" or entry.get("logic_type") == "check_temp_flags_multi" or entry.has("check_temp_flags"):
			var flags = entry.get("check_temp_flags", {})
			connect_to.call(flags.get("default"), 0)
			var idx = 1
			# Assuming dynamic slots order matches key order (fragile but functional for restoration)
			for k in flags.keys():
				if k == "default": continue
				connect_to.call(flags[k], idx)
				idx += 1
