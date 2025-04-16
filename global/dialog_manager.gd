class_name DialogScene
extends Node

@export var dialog_scene_data: DialogSceneResource

@onready var parser := DialogParser.new()
@onready var line_spawner: DialogLineSpawner = $CanvasLayer/DialogLineSpawner

#@onready var narration_box = $NarrationBox
@onready var choice_box: ChoiceBox = $CanvasLayer/ChoiceBox

#@onready var speech_bubble = $SpeechBubble
@onready var background: TextureRect = $Background
@onready var char_port_main: Sprite2D = $CharacterPortraitMain

signal dialog_ended

var dialogue: Array = []
var current_index: int = 0
var character_map: Dictionary[StringName, CharacterResource] = {}

var chunk_list: Array = []
var chunk_index: int = 0
var waiting_for_input: bool = false
var current_choice_entry: Dictionary = {}

var flags := {}

func _ready():
	if dialog_scene_data:
		apply_scene_resource(dialog_scene_data)
	else:
		push_warning("No DialogSceneResource assigned.")

	choice_box.choice_selected.connect(choose)
	show_next_line()


func apply_scene_resource(data: DialogSceneResource) -> void:
	# Background
	$Background.texture = data.background_texture

	# Music
	if data.music:
		MusicPlayer.play(data.music, true)  # true = stop others first

	# Ambience
	if data.ambience:
		$AmbiencePlayer.stream = data.ambience
		$AmbiencePlayer.play()

	# Flags
	for flag_name in data.flags_set_on_start.keys():
		flags[flag_name] = data.flags_set_on_start[flag_name]

	# Character map (convert array to dictionary)
	character_map.clear()
	for entry in data.characters:
		if entry is CharacterEntry:
			character_map[entry.id] = entry.character_resource

	# Load dialogue
	load_dialogue(data.dialogue_path)


func _input(event):
	if GameUI.is_ui_open():
		return  # block dialog from responding while UI is open

	if event.is_action_pressed("ui_accept") and !choice_box.visible and waiting_for_input:
		waiting_for_input = false
		show_next_line()

func load_dialogue(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		dialogue = JSON.parse_string(content)
		print("Dialogue loaded: ", dialogue.size(), " lines")

		# ✅ Start with the first entry immediately
		current_index = 0
		chunk_list.clear()
		chunk_index = 0
#		show_next_line()
	else:
		push_error("Failed to load dialogue at: " + path)


func show_next_line():
	print("▶️ show_next_line() called. Index:", current_index)
	if current_index >= dialogue.size():
		print("End of dialogue.")
		clear_dialog()
		return

	var entry: Dictionary = dialogue[current_index]

	if entry.has("clear") and entry["clear"]:
		print("🧹 Entry has 'clear: true'")
		line_spawner.clear_lines()
	
	if entry.has("end") and entry["end"] == true:
		print("🛑 Entry has end:true, ending dialog.")
		end_dialog()
		return

	choice_box.hide()

	# Process next chunk if available
	if chunk_list.size() > 0 and chunk_index < chunk_list.size():
		var chunk = chunk_list[chunk_index]
		var speaker = entry.get("name", "")
		line_spawner.spawn_chunk(chunk, speaker, character_map)

		chunk_index += 1
		waiting_for_input = true
		return

	# If all chunks are done, move to next entry
	if chunk_list.size() > 0 and chunk_index >= chunk_list.size():
		chunk_list.clear()
		chunk_index = 0

		if entry.has("set_flag"):
			var flag_name = entry["set_flag"]
			flags[flag_name] = true
			print("🔖 Set flag:", flag_name)

		if entry.has("next"):
			var next_id = entry["next"]
			var next_index = _find_entry_index_by_id(next_id)
			if next_index != -1:
				current_index = next_index
				show_next_line()
				return

		current_index += 1
		show_next_line()
		return

	# New entry — process based on type
	print("Now showing entry:", entry)
	print("🔍 Entry type:", entry.get("type", ""))
	
	match entry.get("type", ""):
		"narration":
			chunk_list = parser.parse_dialog_chunks(entry.get("text", ""))
			print("📦 chunk_list after parse:", chunk_list)
			chunk_index = 0
			begin_entry_chunks()
			return

		"npc":
			chunk_list = parser.parse_dialog_chunks(entry.get("text", ""))
			chunk_index = 0
			begin_entry_chunks()
			return

		"choice":
			current_choice_entry = entry
			choice_box.show_choices(entry.options)
			choice_box.show()
			waiting_for_input = false
			return

		"command":
			handle_command(entry.command)
			current_index += 1
			waiting_for_input = true
			return
		
		"logic":
			handle_flag_check(entry)
			return


func choose(index: int):
	print("✅ CHOICE SELECTED: ", index)

	if current_choice_entry.is_empty():
		print("❌ No valid choice entry stored.")
		return

	clear_dialog()

	# Fetch the next ID from selected option
	var next_id = current_choice_entry.options[index].next
	print("➡️ Next ID: ", next_id)

	var next_index = _find_entry_index_by_id(next_id)
	if next_index == -1:
		print("❌ Next ID not found in dialogue.")
		return

	current_index = next_index
	current_choice_entry = {}

	# Fetch and process the entry immediately
	var entry = dialogue[current_index]
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
		"command":
			handle_command(entry.get("command", ""))
			current_index += 1
			show_next_line()
		"logic":
			handle_flag_check(entry)
		_:
			show_next_line()


func _find_entry_index_by_id(id: String) -> int:
	for i in dialogue.size():
		if dialogue[i].has("id") and dialogue[i].id == id:
			return i
	return -1


func handle_flag_check(entry: Dictionary) -> void:
	if not entry.has("check_flags"):
		push_error("❌ Logic entry missing 'check_flags'")
		return

	var logic: Dictionary = entry.get("check_flags", {})

	# Safely convert flags list to Array[String]
	var flags_to_check: Array[String] = []
	for flag in logic.get("flags", []):
		if typeof(flag) == TYPE_STRING:
			flags_to_check.append(flag)

	# Get success and fail targets safely as strings
	var success_target: String = str(logic.get("on_success", ""))
	var fail_target: String = str(logic.get("on_fail", ""))

	print("🧠 Checking flags:", flags_to_check)

	var all_flags_set := true
	for flag_name in flags_to_check:
		if not flags.get(flag_name, false):
			all_flags_set = false
			break

	if all_flags_set:
		print("✅ All flags met! Jumping to:", success_target)
		current_index = _find_entry_index_by_id(success_target)
	else:
		print("❌ Flags not met. Jumping to:", fail_target)
		current_index = _find_entry_index_by_id(fail_target)

	if current_index != -1:
		show_next_line()
	else:
		push_error("❌ Could not find target ID after flag check.")


func handle_command(cmd: String):
	match cmd:
		"clear_all":
			clear_dialog()
		"SHOW_PORTRAIT":
			show_character_portrait(dialogue[current_index].name)
		"HIDE_PORTRAIT":
			hide_character_portrait()


func clear_dialog():
	line_spawner.clear_lines()
	choice_box.hide()


func end_dialog():
	print("🎬 Ending dialog.")
	clear_dialog()
	emit_signal("dialog_ended")  # Optional: connect to trigger scene logic


func show_character_portrait(name: String):
	var character = character_map.get(name)
	if character and character.portrait:
		char_port_main.texture = character.portrait
		char_port_main.modulate.a = 0.0 # start transparent
		char_port_main.show()

		var tween := create_tween()
		tween.tween_property(char_port_main, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		print("❌ No character or portrait found for:", name)


func hide_character_portrait():
	if char_port_main.visible:
		var tween := create_tween()
		tween.tween_property(char_port_main, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		char_port_main.hide()


func begin_entry_chunks():
	if chunk_list.size() > 0:
		var chunk = chunk_list[0]
		var speaker = dialogue[current_index].get("name", "")
		line_spawner.spawn_chunk(chunk, speaker, character_map)

		chunk_index = 1
		waiting_for_input = true
