class_name DialogScene
extends Node

@export var dialog_scene_data: DialogSceneResource

@onready var parser := DialogParser.new()
@onready var narration_box = $NarrationBox
@onready var choice_box = $ChoiceBox
@onready var speech_bubble = $SpeechBubble
@onready var background: TextureRect = $Background
@onready var char_port_main: Sprite2D = $CharacterPortraitMain

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
		$MusicPlayer.stream = data.music
		$MusicPlayer.play()

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
	if event.is_action_pressed("ui_accept") and !choice_box.visible and waiting_for_input:
		waiting_for_input = false
		show_next_line()
		print("→ Chunks left:", chunk_list.size() - chunk_index)
		print("→ Current index:", current_index)

func load_dialogue(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		dialogue = JSON.parse_string(content)
		print("Dialogue loaded: ", dialogue.size(), " lines")

		# ✅ Start with the first entry immediately
		current_index = 0
		chunk_list = parser.parse_dialog_chunks(dialogue[0]["text"])
		chunk_index = 0
		show_next_line()
	else:
		push_error("Failed to load dialogue at: " + path)

func show_next_line():
	choice_box.hide()

	# Process next chunk if available
	if chunk_list.size() > 0 and chunk_index < chunk_list.size():
		var chunk = chunk_list[chunk_index]
		match chunk["type"]:
			"narration":
				narration_box.set_text(chunk["text"])
				narration_box.show()
			"speech":
				show_speech_bubble(chunk["text"], dialogue[current_index].name)
				speech_bubble.show()

		chunk_index += 1
		waiting_for_input = true
		return

	# If all chunks are done (and we had some), advance
	if chunk_list.size() > 0 and chunk_index >= chunk_list.size():
		chunk_list.clear()
		chunk_index = 0

		var entry = dialogue[current_index]

		if entry.has("set_flag"):
			var flag_name = entry["set_flag"]
			flags[flag_name] = true
			print("🔖 Set flag: ", flag_name)

		if entry.has("next"):
			var next_id = entry["next"]
			var next_index = _find_entry_index_by_id(next_id)
			if next_index != -1:
				current_index = next_index
				show_next_line()
				return

		current_index += 1
#		waiting_for_input = true
		show_next_line()
		return

	# End of dialogue
	if current_index >= dialogue.size():
		print("End of dialogue.")
		clear_dialog()
		return

	# Get the current entry to process
	var entry = dialogue[current_index]
	print("Now showing entry: ", entry)

	match entry.type:
		"narration":
			chunk_list = [{ "type": "narration", "text": entry.text }]
			chunk_index = 0
			begin_entry_chunks()
			return

		"npc":
			chunk_list = parser.parse_dialog_chunks(entry["text"])
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
			# We assume next entry is something visual — wait for input to process it
			waiting_for_input = true
			return


func choose(index: int):
	print("✅ CHOICE SELECTED: ", index)

	if current_choice_entry.is_empty():
		print("❌ No valid choice entry stored.")
		return

	clear_dialog()

	var next_id = current_choice_entry.options[index].next
	print("➡️ Next ID: ", next_id)

	var next_index = _find_entry_index_by_id(next_id)
	if next_index != -1:
		current_index = next_index
		current_choice_entry = {}

		var new_entry = dialogue[current_index]
		print("🆕 New entry: ", new_entry)

		match new_entry.type:
			"narration":
				chunk_list = [{ "type": "narration", "text": new_entry.text }]
				chunk_index = 0
				show_next_line()

			"npc":
				chunk_list = parser.parse_dialog_chunks(new_entry["text"])
				chunk_index = 0
				show_next_line()

			"choice":
				current_choice_entry = new_entry
				choice_box.show_choices(new_entry.options)
				choice_box.show()

			"command":
				handle_command(new_entry.command)
				current_index += 1
				show_next_line()
	else:
		print("❌ Next ID not found in dialogue.")


func _find_entry_index_by_id(id: String) -> int:
	for i in dialogue.size():
		if dialogue[i].has("id") and dialogue[i].id == id:
			return i
	return -1


func handle_command(cmd: String):
	match cmd:
		"clear_all":
			clear_dialog()
		"SHOW_PORTRAIT":
			show_character_portrait(dialogue[current_index].name)
		"HIDE_PORTRAIT":
			hide_character_portrait()


func clear_dialog():
	narration_box.set_text("")
	speech_bubble.set_text("", Color.WHITE)
	narration_box.hide()
	speech_bubble.hide()


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
		speech_bubble.hide()
		char_port_main.hide()


func show_speech_bubble(text: String, speaker: String):
	var char_res: CharacterResource = character_map.get(speaker, null)
	if char_res:
		speech_bubble.set_text(
			text,
			char_res.color,
			char_res.speech_bubble_color,
			char_res.speech_bubble_font
		)
	else:
		speech_bubble.set_text(text)

func begin_entry_chunks():
	if chunk_list.size() > 0:
		var chunk = chunk_list[0]
		match chunk["type"]:
			"narration":
				narration_box.set_text(chunk["text"])
				narration_box.show()
			"speech":
				show_speech_bubble(chunk["text"], dialogue[current_index].name)
				speech_bubble.show()

		chunk_index = 1
		waiting_for_input = true
