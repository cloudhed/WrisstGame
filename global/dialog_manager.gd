class_name DialogManager
extends Node

@export var dialog_scene_data: DialogSceneResource

@onready var command_executor := DialogCommandExecutor.new(GameState)
@onready var logic_handler := DialogLogicHandler.new()
@onready var scene_loader := DialogSceneLoader.new()
@onready var flow_manager := DialogFlowManager.new()

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
var character_map: Dictionary[StringName, CharacterResource] = {}
var slide_deck: SlideDeck
var flags: Dictionary = {}

func _ready() -> void:
	if dialog_scene_data:
		start_dialog(dialog_scene_data)
	else:
		push_warning("⚠️ No DialogSceneResource assigned to DialogManager.")
	
		# Connect global dialog scene change signal
	if not Events.dialog_scene_change_requested.is_connected(_on_dialog_scene_change_requested):
		Events.dialog_scene_change_requested.connect(_on_dialog_scene_change_requested)


func start_dialog(data: DialogSceneResource) -> void:
	print("📲 Starting dialog with scene:", data)
	dialog_scene_data = data

		# 🧼 Clean up old scene_loader and flow_manager if they exist
	if scene_loader:
		scene_loader.queue_free()
	scene_loader = DialogSceneLoader.new()
	add_child(scene_loader)
	scene_loader.hotspot_triggered.connect(_on_hotspot_triggered)
	
		# Same for flow_manager
	if flow_manager:
		flow_manager.queue_free()
	flow_manager = DialogFlowManager.new()
	
	clear_visuals()

	scene_loader.load_scene(
		self, data,
		zone_container, mist_container,
		background,
		character_map,
		func(sd): slide_deck = sd,
		func(): return flags
	)
	
	## Defer signal connection until children are added
	#call_deferred("_connect_hotspot_scene_switch_signals")

	if load_dialogue(data.dialogue_path):
		add_child(flow_manager)
		flow_manager.dialog_ended.connect(_on_dialog_ended)
		flow_manager.jump_requested.connect(flow_manager.jump_to_id) # ✅ FIXED: CONNECT SIGNAL

		flow_manager.initialize(
			dialogue,
			character_map,
			slide_deck,
			flags,
			{
				"line_spawner": line_spawner,
				"choice_box": choice_box,
				"parser": parser,
				"command_executor": command_executor,
				"logic_handler": logic_handler,
				"dialog_manager": self,
				"portrait_node": char_portrait,         # ✅ ADD THIS
				"portrait2_node": char_extra,           # ✅ AND THIS
				"slideshow_node": slideshow_image,
				"slide_container": slide_container
			}
		)

		await get_tree().process_frame
		flow_manager.show_next_line()


func _on_dialog_scene_change_requested(area_key: String) -> void:
	print("🎯 Scene change requested for area key:", area_key)
	var new_data := DialogSceneSelector.get_scene(area_key)
	print("📦 Got scene data:", new_data)
	if new_data:
		start_dialog(new_data)
	else:
		push_error("❌ Could not load dialog scene for key: " + area_key)


func _on_dialog_ended() -> void:
	print("🎬 Dialog ended signal received.")
	emit_signal("dialog_ended")


func _on_hotspot_triggered(target_id: String) -> void:
	print("🚪 Hotspot triggered! Target Dialog ID:", target_id)
	flow_manager.jump_requested.emit(target_id)  # Passes to flow manager


func load_dialogue(path: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text()
		dialogue = JSON.parse_string(content)
		print("📖 Dialogue loaded:", dialogue.size(), "lines")
		return true
	else:
		push_error("❌ Failed to load dialogue at: " + path)
		return false


func _input(event: InputEvent) -> void:
	if flow_manager == null or choice_box.visible:
		return

	if event is InputEventKey and event.is_action_pressed("ui_accept"):
		flow_manager.waiting_for_input = false
		flow_manager.show_next_line()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		flow_manager.waiting_for_input = false
		flow_manager.show_next_line()


func load_additional_dialog(relative_path: String) -> void:
	var full_path := "res://Dialog/" + relative_path
	var file := FileAccess.open(full_path, FileAccess.READ)
	if file:
		var content: String = file.get_as_text()
		var new_lines: Array = JSON.parse_string(content)
		dialogue.append_array(new_lines)
		print("📥 Appended", new_lines.size(), "dialog lines from:", relative_path)
	else:
		push_error("❌ Failed to load additional dialog from: " + full_path)


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


func clear_visuals() -> void:
	# 🎵 Fade out music
	MusicPlayer.fade_out()

	# 🌬️ Stop all ambient layers with fade
	AmbiencePlayer.stop_all(true)
	
	# 🧹 Clear character portraits
	char_portrait.texture = null
	char_portrait.hide()

	char_extra.texture = null
	char_extra.hide()

	# 🧹 Clear slideshow image
	slideshow_image.texture = null
	slideshow_image.hide()

	# 🧹 Clear background
	background.texture = null

	# 🧹 Clear slide container (just in case it has leftovers)
	for child in slide_container.get_children():
		child.queue_free()

	# 🧹 Optionally clear any mist/zone effects
	for child in mist_container.get_children():
		child.queue_free()

	# 🧹 Clear any leftover characters
	for child in character_container.get_children():
		if child != char_portrait and child != char_extra:
			child.queue_free()

	print("🧼 Visuals cleared for new dialog scene.")

#func _connect_hotspot_scene_switch_signals() -> void:
	#for hotspot in get_tree().get_nodes_in_group("hotspots"):
		#if hotspot is Hotspot:
			#if not hotspot.dialog_scene_change_requested.is_connected(_on_dialog_scene_change_requested):
				#hotspot.dialog_scene_change_requested.connect(_on_dialog_scene_change_requested)
	#print("🔗 Connected all hotspot scene-switch signals via group.")
