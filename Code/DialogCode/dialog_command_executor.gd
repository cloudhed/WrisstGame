class_name DialogCommandExecutor
extends Node

var game_state: Node

func _init(_game_state: Node):
	game_state = _game_state

func execute(cmd: String, context: Dictionary = {}) -> void:
	var parts := cmd.split(" ")
	var command: String = parts[0]
	context["raw_command"] = cmd  # preserve full original command
	
	match command:
		"clear_all":
			if context.has("line_spawner") and context["line_spawner"]:
				context["line_spawner"].clear_lines()
			if context.has("choice_box") and context["choice_box"]:
				context["choice_box"].hide()
		"SHOW_PORTRAIT":
			_show_character_portrait(context)
		"HIDE_PORTRAIT":
			_hide_character_portrait(context)
		"SHOW_EXTRA":
			_show_character_extra(context)
		"HIDE_EXTRA":
			_hide_character_extra(context)
		"SHOW_SLIDESHOW":
			_show_slideshow(context)
		"HIDE_SLIDESHOW":
			_hide_slideshow(context)
		"SHOW_SCENE":
			_show_named_slide(context)
		"HIDE_SCENE":
			_hide_scene(context)
		"SHOW_ZONE":
			_show_zone(context)
		"PLAY_MUSIC":
			_play_music(context)
		"STOP_MUSIC":
			_stop_music()
		"FADE_MUSIC_OUT":
			_fade_out_music()
		"PLAY_AMBIENCE":
			_play_layered_ambience(context)
		"STOP_AMBIENCE":
			_stop_layered_ambience(context)
		"STOP_ALL_AMBIENCE":
			_stop_all_ambience()
		"START_COMBAT":
			_start_combat(context)
		_:
			_handle_money_command(cmd)

# === MONEY COMMANDS ===

func _handle_money_command(cmd: String) -> void:
	var parts: Array = cmd.split(" ")
	if parts.size() != 2:
		print("❌ Invalid money command format:", cmd)
		return

	var amount: int = 0
	var action: String = parts[0].to_lower()
	
	if parts[1].is_valid_int():
		amount = parts[1].to_int()
	else:
		print("❌ Invalid number in command:", parts[1])
		return

	match action:
		"add_ore":
			game_state.add_ore(amount)
		"remove_ore":
			game_state.remove_ore(amount)
		"add_crowns":
			game_state.add_crowns(amount)
		"remove_crowns":
			game_state.remove_crowns(amount)
		"add_drots":
			game_state.add_drots(amount)
		"remove_drots":
			game_state.remove_drots(amount)
		_:
			print("❌ Unknown money command:", cmd)


# === PORTRAITS ===

func _show_character_portrait(context: Dictionary) -> void:
	var char_name: String = context.get("name", "")
	var raw_cmd: String = context.get("raw_command", "")
	var char_port_main: TextureRect = context.get("portrait_node")
	var character_map: Dictionary = context.get("character_map", {})

	if char_port_main == null:
		print("❌ portrait_node is missing in context!")
		return

	var parts := raw_cmd.split(" ")
	var portrait_id: String = ""
	if parts.size() > 1:
		portrait_id = parts[1]
	else:
		print("❌ Missing portrait ID in SHOW_PORTRAIT command:", raw_cmd)
		return

	var character_res := character_map.get(char_name) as CharacterResource
	if character_res == null:
		print("❌ Character not found or wrong type for:", char_name)
		return

	if character_res.portrait == null:
		print("❌ No portrait deck found for character:", char_name)
		return

	# 🔍 Find portrait by ID
	var selected_texture: Texture2D = null
	for entry in character_res.portrait.portraits:
		if entry.id == portrait_id:
			selected_texture = entry.portrait
			break

	if selected_texture == null:
		print("❌ Portrait ID not found in deck:", portrait_id)
		return

	# 🎭 Fade out current portrait if one is shown
	if char_port_main.visible and char_port_main.modulate.a > 0.0:
		var fade_out := char_port_main.create_tween()
		fade_out.tween_property(char_port_main, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	# 🖼️ Switch to new texture
	char_port_main.texture = selected_texture
	char_port_main.modulate.a = 0.0
	char_port_main.show()

	# 🌅 Fade in new portrait
	var fade_in := char_port_main.create_tween()
	fade_in.tween_property(char_port_main, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hide_character_portrait(context: Dictionary) -> void:
	var char_port_main: TextureRect = context.get("portrait_node")
	if char_port_main and char_port_main.visible:
		var tween: Tween = char_port_main.create_tween()
		tween.tween_property(char_port_main, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		char_port_main.hide()

#EXTRA PORTRAIT
func _show_character_extra(context: Dictionary) -> void:
	var char_name: String = context.get("name", "")
	var raw_cmd: String = context.get("raw_command", "")
	var char_port_extra: TextureRect = context.get("portrait2_node")
	var character_map: Dictionary = context.get("character_map", {})

	if char_port_extra == null:
		print("❌ portrait2_node is missing in context!")
		return

	var parts := raw_cmd.split(" ")
	var portrait_id: String = ""
	if parts.size() > 1:
		portrait_id = parts[1]
	else:
		print("❌ Missing portrait ID in SHOW_EXTRA command:", raw_cmd)
		return

	var character_res := character_map.get(char_name) as CharacterResource
	if character_res == null:
		print("❌ Character not found or wrong type for:", char_name)
		return

	if character_res.portrait == null:
		print("❌ No portrait deck found for character:", char_name)
		return

	# 🔍 Find portrait by ID
	var selected_texture: Texture2D = null
	for entry in character_res.portrait.portraits:
		if entry.id == portrait_id:
			selected_texture = entry.portrait
			break

	if selected_texture == null:
		print("❌ Portrait ID not found in deck:", portrait_id)
		return

	# 🎭 Fade out current portrait if one is shown
	if char_port_extra.visible and char_port_extra.modulate.a > 0.0:
		var fade_out := char_port_extra.create_tween()
		fade_out.tween_property(char_port_extra, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	# 🖼️ Switch to new texture
	char_port_extra.texture = selected_texture
	char_port_extra.modulate.a = 0.0
	char_port_extra.show()

	# 🌅 Fade in new portrait
	var fade_in := char_port_extra.create_tween()
	fade_in.tween_property(char_port_extra, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hide_character_extra(context: Dictionary) -> void:
	var char_port_extra: TextureRect = context.get("portrait2_node")
	if char_port_extra and char_port_extra.visible:
		var tween: Tween = char_port_extra.create_tween()
		tween.tween_property(char_port_extra, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await tween.finished
		char_port_extra.hide()


# === STATIC SLIDESHOW ===

func _show_slideshow(context: Dictionary) -> void:
	var cmd: String = context.get("raw_command", "")
	var parts: Array[String] = cmd.split(" ")
	if parts.size() < 2:
		print("❌ SHOW_SLIDESHOW missing file path.")
		return

	var path: String = parts[1]
	var slideshow_node: TextureRect = context.get("slideshow_node")
	if not slideshow_node:
		print("❌ No slideshow node passed to context.")
		return

	var tex: Texture2D = load(path)
	if tex:
		slideshow_node.texture = tex
		slideshow_node.show()
	else:
		print("❌ Could not load slideshow image at path:", path)

func _hide_slideshow(context: Dictionary) -> void:
	var slideshow_node: TextureRect = context.get("slideshow_node")
	if slideshow_node:
		slideshow_node.hide()


# === DYNAMIC SCENE SLIDES ===

func _show_named_slide(context: Dictionary) -> void:
	var raw_cmd = context.get("raw_command", "")
	if typeof(raw_cmd) != TYPE_STRING or raw_cmd == "":
		print("❌ raw_command is missing or not a string:", raw_cmd)
		return

	print("🧩 raw_command context:", context)
	var parts: Array = raw_cmd.split(" ")
	if parts.size() < 2:
		print("❌ Missing slide name in SHOW_SCENE:", raw_cmd)
		return

	var slide_name: StringName = parts[1]
	var deck: SlideDeck = context.get("slide_deck")
	var container: Node = context.get("slide_container")

	if not deck or not container:
		print("❌ Slide deck or container missing.")
		return

	var found: bool = false
	for entry in deck.slides:
		if entry.id == slide_name:
			queue_free_children(container)
			var slide_scene: PackedScene = entry.scene
			var slide_instance: Node = slide_scene.instantiate()
			container.add_child(slide_instance)
			found = true
			break

	if not found:
		print("❌ Slide not found in deck:", slide_name)


func _hide_scene(context: Dictionary) -> void:
	var container: Node = context.get("slide_container")
	if container:
		queue_free_children(container)


# === START COMBAT ===
func _start_combat(context: Dictionary) -> void:
	var dialog_manager = context.get("dialog_manager")
	if dialog_manager == null:
		print("❌ dialog_manager not passed to START_COMBAT context.")
		return
	
	print("🎬 START_COMBAT called from dialog. Ending dialog...")
	dialog_manager.end_dialog()


# === SHOW_ZONE ===
func _show_zone(context: Dictionary) -> void:
	var cmd: String = context.get("raw_command", "")
	var parts: PackedStringArray = cmd.split(" ")
	if parts.size() < 2:
		print("❌ Missing zone scene path for SHOW_ZONE:", cmd)
		return

	var zone_path_sub := parts[1]  # Example: "Klyftet/KlyftetExtInnDay"
	var full_path: String = "res://Narrative/DialogScenes/Locations/%s.tscn" % zone_path_sub

	var zone_scene: Resource = load(full_path)

	if not zone_scene or not zone_scene is PackedScene:
		print("❌ Could not load zone scene as PackedScene:", full_path)
		return

	var dialog_manager: DialogManager = context.get("dialog_manager") as DialogManager
	if dialog_manager == null:
		print("❌ No dialog_manager in context!")
		return

	# 🧼 Clear current zone
	for child in dialog_manager.zone_container.get_children():
		child.queue_free()

	var new_zone: Node2D = (zone_scene as PackedScene).instantiate() as Node2D
	dialog_manager.zone_container.add_child(new_zone)
	new_zone.position = Vector2.ZERO

	# 🔌 Assign dialog_manager if the new zone is a ZoneScene
	if new_zone is ZoneScene:
		(new_zone as ZoneScene).dialog_manager = dialog_manager
	
	# 🕓 Wait for zone to be ready before connecting hotspots
	await new_zone.ready

	# 🔌 Reconnect hotspot signals
	for hotspot in new_zone.get_children():
		if hotspot is Hotspot:
			hotspot.hotspot_triggered.connect(dialog_manager._on_hotspot_triggered)


# === LOAD DIALOG ===
func _load_dialog_file(context: Dictionary) -> void:
	var cmd: String = context.get("raw_command", "")
	var parts: Array = cmd.split(" ")
	if parts.size() < 2:
		print("❌ Missing path in LOAD_DIALOG")
		return

	var dialog_path: String = parts[1]

	var dialog_manager: DialogManager = context.get("dialog_manager")
	if dialog_manager == null:
		print("❌ No dialog_manager in context!")
		return

	dialog_manager.load_additional_dialog(dialog_path)


# === SOUND EFFECTS ===
func _play_music(context: Dictionary) -> void:
	var raw_cmd: String = context.get("raw_command", "")
	var parts: PackedStringArray = raw_cmd.split(" ", false)
	if parts.size() < 2:
		print("❌ PLAY_MUSIC needs path to audio stream.")
		return

	var path: String = parts[1]
	var stream: AudioStream = load(path) as AudioStream
	if stream:
		MusicPlayer.play(stream)
	else:
		print("❌ Failed to load music at:", path)


func _stop_music() -> void:
	MusicPlayer.stop()


func _fade_out_music() -> void:
	# Optional smoother fade-out version
	for player in MusicPlayer.get_children():
		if player is AudioStreamPlayer and player.playing:
			var tween: Tween = player.create_tween()
			tween.tween_property(player, "volume_db", -60.0, 2.0)
			tween.tween_callback(func(): player.stop())


func _play_layered_ambience(context: Dictionary) -> void:
	var raw_cmd: String = context.get("raw_command", "")
	var parts: PackedStringArray = raw_cmd.split(" ", false)
	if parts.size() < 3:
		print("❌ PLAY_AMBIENCE expects: @PLAY_AMBIENCE <tag> <path>")
		return

	var tag: String = parts[1]
	var path: String = parts[2]
	var stream: AudioStream = load(path) as AudioStream
	if stream:
		AmbiencePlayer.play_layer(tag, stream)
	else:
		print("❌ Could not load ambience stream:", path)


func _stop_layered_ambience(context: Dictionary) -> void:
	var raw_cmd: String = context.get("raw_command", "")
	var parts: PackedStringArray = raw_cmd.split(" ", false)
	if parts.size() < 2:
		print("❌ STOP_AMBIENCE expects: @STOP_AMBIENCE <tag>")
		return

	var tag: String = parts[1]
	AmbiencePlayer.stop_layer(tag)


func _stop_all_ambience() -> void:
	AmbiencePlayer.stop_all(true)  # true = fade out


# === UTILITY ===

func queue_free_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
