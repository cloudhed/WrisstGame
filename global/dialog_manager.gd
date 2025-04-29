class_name DialogManager
extends Node

@export var dialog_scene_data: DialogSceneResource


@onready var command_executor := DialogCommandExecutor.new(GameState)
@onready var logic_handler := DialogLogicHandler.new(GameState)

@onready var parser := DialogParser.new()
@onready var line_spawner: DialogLineSpawner = $CanvasLayer/DialogLineSpawner
@onready var choice_box: ChoiceBox = $CanvasLayer/ChoiceBox

@onready var background: TextureRect = $Background

@onready var zone_container: Node2D = $ZoneContainer
@onready var mist_container: Node2D = $MistContainer
@onready var character_container: Node2D = $CharacterContainer

@onready var char_portrait: TextureRect = $CharacterContainer/CharacterPortraitMain
@onready var char_extra: TextureRect = $CharacterContainer/CharacterPortraitExtra

@onready var slideshow_image: TextureRect = $SlideshowImage
@onready var slide_container: Node2D = $CanvasLayer/SlideContainer


signal dialog_ended

var dialogue: Array = []
var current_index: int = 0
var character_map: Dictionary[StringName, CharacterResource] = {}
var slide_deck: SlideDeck

var chunk_list: Array = []
var chunk_index: int = 0
var last_command_index: int = -1
var waiting_for_input: bool = false
var current_choice_entry: Dictionary = {}

var flags: Dictionary = {}

func _ready():
	if dialog_scene_data:
		apply_scene_resource(dialog_scene_data)
	else:
		push_warning("No DialogSceneResource assigned.")

	if not choice_box.choice_selected.is_connected(choose):
		choice_box.choice_selected.connect(choose)

	show_next_line()


func start_dialog(data: DialogSceneResource) -> void:
	dialog_scene_data = data
	apply_scene_resource(dialog_scene_data)

	await get_tree().process_frame
	show_next_line()


func apply_scene_resource(data: DialogSceneResource) -> void:
	# 🗑️ Clear previous Zone scene if needed
	for child in zone_container.get_children():
		child.queue_free()
	
	# 🗑️ Clear previous Mist if needed
	for child in mist_container.get_children():
		child.queue_free()

	# 🏙️ Load Zone Scene if available
	if data.zone_scene:
		var zone_instance: Node2D = data.zone_scene.instantiate() as Node2D
		zone_container.add_child(zone_instance)
		zone_instance.position = Vector2.ZERO # 🔥 Reset position to (0,0)
		
				# 🔥 CONNECT HOTSPOTS HERE
		for hotspot in zone_instance.get_children():
			if hotspot is Hotspot:
				hotspot.hotspot_triggered.connect(_on_hotspot_triggered)
	else:
		background.texture = data.background_texture

	# 🎵 Play music
	if data.music:
		MusicPlayer.play(data.music, true)

	# 🎶 Play ambience
	if data.ambience:
		$AmbiencePlayer.stream = data.ambience
		$AmbiencePlayer.play()

	# 🏷️ Set flags at scene start
	for flag_name in data.flags_set_on_start.keys():
		flags[flag_name] = data.flags_set_on_start[flag_name]

	# 🎞️ Set slide deck
	slide_deck = data.slide_deck
	if not slide_deck:
		print("⚠️ WARNING: No SlideDeck assigned in DialogSceneResource.")

	# 👥 Load character resources
	character_map.clear()
	for entry in data.characters:
		if entry is CharacterEntry:
			character_map[entry.id] = entry.character_resource

	# 📖 Load dialogue
	load_dialogue(data.dialogue_path)


func _input(event: InputEvent) -> void:
	if not waiting_for_input or choice_box.visible:
		return

	if event is InputEventKey and event.is_action_pressed("ui_accept"):
		print("✅ Advancing dialogue with ui_accept")
		waiting_for_input = false
		show_next_line()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("✅ Advancing dialogue with mouse click")
		waiting_for_input = false
		show_next_line()


func load_dialogue(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text()
		dialogue = JSON.parse_string(content)
		print("Dialogue loaded: ", dialogue.size(), " lines")

		current_index = 0
		chunk_list.clear()
		chunk_index = 0
	else:
		push_error("Failed to load dialogue at: " + path)


func show_next_line() -> void:
	print("▶️ show_next_line() called. Index:", current_index)

	if check_dialog_end():
		return

	var entry: Dictionary = dialogue[current_index]
	choice_box.hide()

	if handle_special_entry(entry):
		return

	handle_entry_command(entry)

	if show_next_chunk(entry):
		return

	process_entry_type(entry)


func jump_to_dialog(dialog_id: String) -> void:
	for i in range(dialogue.size()):
		var entry: Dictionary = dialogue[i]
		if entry.has("id") and entry["id"] == dialog_id:
			print("🔄 Jumping to dialog ID:", dialog_id)
			current_index = i
			show_next_line()
			return
	
	print("❌ Dialog ID not found:", dialog_id)


func _on_hotspot_triggered(target_id: String) -> void:
	print("🚪 Hotspot triggered! Target Dialog ID:", target_id)
	jump_to_dialog(target_id)


func check_dialog_end() -> bool:
	if current_index >= dialogue.size():
		print("End of dialogue.")
		clear_dialog()
		return true
	return false


func handle_special_entry(entry: Dictionary) -> bool:
	if entry.has("clear") and entry["clear"]:
		line_spawner.clear_lines()

	if entry.has("end") and entry["end"] == true:
		end_dialog()
		return true

	if entry.get("type", "") == "command":
		var cmd: String = entry.get("command", entry.get("text", ""))
		if cmd is String and not cmd.is_empty():
			handle_command(cmd)

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
			print("🧩 Inline command found:", cmd)
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
			print("🔖 Set flag:", flag_name)

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



func choose(index: int) -> void:
	print("✅ CHOICE SELECTED: ", index)

	if current_choice_entry.is_empty():
		print("❌ No valid choice entry stored.")
		return

	clear_dialog()

	var next_id: String = current_choice_entry.options[index].next
	print("➡️ Next ID: ", next_id)

	var next_index: int = _find_entry_index_by_id(next_id)
	if next_index == -1:
		print("❌ Next ID not found in dialogue.")
		return

	current_index = next_index
	current_choice_entry = {}
	show_next_line()


func _find_entry_index_by_id(id: String) -> int:
	for i in dialogue.size():
		if dialogue[i].has("id") and dialogue[i]["id"] == id:
			return i
	return -1


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

	var context: Dictionary = {
		"line_spawner": line_spawner,
		"choice_box": choice_box,
		"portrait_node": char_portrait,
		"portrait2_node": char_extra,
		"name": dialogue[current_index].get("name", ""),
		"character_map": character_map,
		"slideshow_node": slideshow_image,
		"raw_command": cmd,
		"slide_deck": slide_deck,
		"slide_container": slide_container,
		"dialog_manager": self,
	}

	command_executor.execute(cmd.trim_prefix("@"), context)


func clear_dialog() -> void:
	line_spawner.clear_lines()
	choice_box.hide()


func end_dialog() -> void:
	print("🎬 Ending dialog.")
	clear_dialog()
	emit_signal("dialog_ended")


func show_character_portrait(name: String) -> void:
	var character = character_map.get(name)
	if character and character.portrait:
		char_portrait.texture = character.portrait
		char_portrait.modulate.a = 0.0
		char_portrait.show()
		

		var tween: Tween = create_tween()
		tween.tween_property(char_portrait, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		print("❌ No character or portrait found for:", name)


func hide_character_portrait() -> void:
	if char_portrait.visible:
		var tween: Tween = create_tween()
		tween.tween_property(char_portrait, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		char_portrait.hide()

func show_character_extra(name: String) -> void:
	var character = character_map.get(name)
	if character and character.portrait:
		char_extra.texture = character.portrait
		char_extra.modulate.a = 0.0
		char_extra.show()
		

		var tween: Tween = create_tween()
		tween.tween_property(char_extra, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		print("❌ No character or portrait found for:", name)


func hide_character_extra() -> void:
	if char_extra.visible:
		var tween: Tween = create_tween()
		tween.tween_property(char_extra, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		char_extra.hide()


func begin_entry_chunks() -> void:
	if chunk_list.size() > 0:
		var chunk = chunk_list[0]
		var speaker = dialogue[current_index].get("name", "")
		line_spawner.spawn_chunk(chunk, speaker, character_map)

		chunk_index = 1
		waiting_for_input = true
