class_name DialogCommandExecutor
extends Node

var game_state: Node

func _init(_game_state: Node):
	game_state = _game_state

func execute(cmd: String, context: Dictionary = {}) -> void:
	var parts := cmd.split(" ")
	var command: String = parts[0]
	var normalized_command: String = command.to_upper()
	context["raw_command"] = cmd  # preserve full original command

	match normalized_command:
		"CLEAR_ALL":
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
		"MUSIC_CLIP":
			_set_music_clip(context)
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
		"LEAVE_ENCOUNTER":
			_leave_encounter(context)
		"SET_SCENE_FROM":
			if parts.size() >= 2:
				GameState.last_scene_id = parts[1]
				print("✅ Scene from manually set to:", GameState.last_scene_id)
		"CHANGE_LOCATION", "LOCATION_CHANGE":
			_change_location(parts)
		"SET_TIME":
			_set_time(parts)
		"RECORD_SPECIES_SEX":
			_record_species_sex(parts, context)
		"OPEN_BARTER":
			_open_barter(context)
		_:
			_handle_game_state_command(cmd, context)


func _change_location(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		print("❌ CHANGE_LOCATION/LOCATION_CHANGE missing area key.")
		return

	var area_key: String = parts[1].strip_edges().to_lower()
	if area_key.is_empty():
		print("❌ CHANGE_LOCATION/LOCATION_CHANGE got empty area key.")
		return

	print("🌍 Dialog command requested location change:", area_key)
	Events.dialog_scene_change_requested.emit(area_key)


func _set_time(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		push_warning("❌ SET_TIME missing argument. Use: @SET_TIME night  or  @SET_TIME day")
		return
	var period := parts[1].strip_edges().to_lower()
	if period == "night":
		GameState.is_night = true
		_sync_clock(2, 0)
		print("🌙 Time set to night (02:00).")
	elif period == "day":
		GameState.is_night = false
		_sync_clock(9, 0)
		print("☀️ Time set to day (09:00).")
	else:
		push_warning("❌ SET_TIME got unknown period: " + period + ". Use 'night' or 'day'.")


func _sync_clock(hours: int, minutes: int) -> void:
	var clock := Manager.get_node_or_null("/root/overworld_node/TimeOfDayControl")
	if clock and clock.has_method("set_current_time"):
		clock.set_current_time(hours, minutes)
	Manager.last_time_of_day = {"hours": hours, "minutes": minutes}
	Manager.last_time_period = "Night" if GameState.is_night else "Day"


func _record_species_sex(parts: PackedStringArray, context: Dictionary) -> void:
	if GameState.player_statistics == null:
		return

	var species_id := StringName("")
	if parts.size() >= 2 and not parts[1].strip_edges().is_empty():
		species_id = StringName(parts[1].strip_edges().to_lower())
	else:
		var dialog_manager = context.get("dialog_manager")
		if dialog_manager:
			var combat_scene = dialog_manager
			while combat_scene != null and not combat_scene.has_method("abort_combat"):
				combat_scene = combat_scene.get_parent()

			if combat_scene:
				var active_enemy = combat_scene.get("active_enemy_stats")
				if active_enemy and active_enemy.has_method("get_species_id"):
					species_id = active_enemy.get_species_id()

	if String(species_id).is_empty():
		species_id = StringName("unknown")

	GameState.player_statistics.record_sex(species_id)

# === BARTER ===

func _open_barter(context: Dictionary) -> void:
	var cmd: String = context.get("raw_command", "")
	var parts: PackedStringArray = cmd.split(" ", false)
	if parts.size() < 2:
		push_error("❌ OPEN_BARTER needs a shop resource path.")
		return

	var shop_path: String = parts[1]
	var shop_res: Resource = load(shop_path)
	if shop_res == null:
		push_error("❌ Could not load ShopInventory: " + shop_path)
		return

	Events.barter_requested.emit(shop_res)


# === MONEY COMMANDS ===

func _handle_game_state_command(cmd: String, context: Dictionary = {}) -> void:
	var parts: Array = cmd.split(" ")
	if parts.size() < 2:
		print("❌ Invalid game state command format:", cmd)
		return

	var action: String = parts[0].to_lower()
	var value: String = parts[1]
	var quantity: int = 1

	if parts.size() >= 3 and parts[2].is_valid_int():
		quantity = parts[2].to_int()

	match action:
		# === Currency ===
		"add_ore":
			game_state.add_ore(value.to_int())
		"remove_ore":
			game_state.remove_ore(value.to_int())
		"add_crowns":
			game_state.add_crowns(value.to_int())
		"remove_crowns":
			game_state.remove_crowns(value.to_int())
		"add_drots":
			game_state.add_drots(value.to_int())
		"remove_drots":
			game_state.remove_drots(value.to_int())

		# === Items ===
		"add_item":
			var item := load("res://Resources/Items/%s.tres" % value) as InventoryItem
			if item:
				game_state.add_item(item, quantity)
			else:
				print("❌ Could not load InventoryItem:", value)

		"remove_item":
			var item := load("res://Resources/Items/%s.tres" % value) as InventoryItem
			if item:
				game_state.remove_item(item, quantity)
			else:
				print("❌ Could not load InventoryItem:", value)
		
		# === Reputation ===
		"add_reputation":
			game_state.add_reputation(value, quantity)

		"remove_reputation":
			game_state.remove_reputation(value, quantity)

		# === Horny ===
		"add_horny":
			game_state.add_horny(value, quantity)

		"remove_horny":
			game_state.remove_horny(value, quantity)

		_:
			print("❌ Unknown game state command:", cmd)



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
			if slide_scene == null:
				print("❌ Slide exists in deck but has no scene assigned:", slide_name)
				return
			var slide_instance: Node = slide_scene.instantiate()
			container.add_child(slide_instance)
			found = true
			break

	if not found:
		var available_ids: Array[String] = []
		for entry in deck.slides:
			available_ids.append(String(entry.id))
		print("❌ Slide not found in deck:", slide_name, " Available IDs:", available_ids)


func _hide_scene(context: Dictionary) -> void:
	var container: Node = context.get("slide_container")
	if container:
		queue_free_children(container)


# === START COMBAT ===
func _start_combat(context: Dictionary) -> void:
	var cmd: String = context.get("raw_command", "")
	var parts: Array = cmd.split(" ")

	var dialog_manager = context.get("dialog_manager")
	if dialog_manager:
		var combat_scene = dialog_manager
		while combat_scene != null and not combat_scene.has_method("begin_combat_from_overlay"):
			combat_scene = combat_scene.get_parent()

		if combat_scene:
			combat_scene.begin_combat_from_overlay()
			return

	var enemy_resource: Resource = null

	if parts.size() >= 2:
		var enemy_path: String = parts[1]
		enemy_resource = load(enemy_path)
	else:
		push_error("❌ START_COMBAT needs enemy resource path outside combat overlay flow.")
		return

	if not enemy_resource:
		push_error("❌ Could not load enemy resource: " + parts[1])
		return

	if dialog_manager == null:
		push_error("❌ dialog_manager not passed to START_COMBAT context.")
		return

	var current_scene = dialog_manager.get_tree().current_scene
	if current_scene == null:
		push_error("❌ START_COMBAT: current_scene is null.")
		return
	
	dialog_manager.disable_dialog_ui()
	var combat = SceneManager.start_combat(enemy_resource, dialog_manager)

	# ✅ Connect combat_ended signal
	if combat and combat.has_signal("combat_ended"):
		combat.combat_ended.connect(dialog_manager.enable_dialog_ui)
	#SceneManager.start_combat(enemy_resource, current_scene.packed_scene)



func _leave_encounter(context: Dictionary) -> void:
	print("🚨 _leave_encounter CALLED. Emitting leave_encounter_requested.")
	var dialog_manager = context.get("dialog_manager")
	if dialog_manager:
		# ✅ SAFELY walk up to Combat scene
		var combat_scene = dialog_manager
		while combat_scene != null and not combat_scene.has_method("abort_combat"):
			combat_scene = combat_scene.get_parent()

		if combat_scene:
			print("🛑 Found combat scene. Calling abort_combat() directly.")
			combat_scene.abort_combat()
		else:
			print("❌ Could not find combat scene with abort_combat().")

	Events.leave_encounter_requested.emit()



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


func _set_music_clip(context: Dictionary) -> void:
	var raw_cmd: String = context.get("raw_command", "")
	var parts: PackedStringArray = raw_cmd.split(" ", false)
	if parts.size() < 2:
		print("❌ MUSIC_CLIP expects: @MUSIC_CLIP <clip_index_or_name>")
		return

	var clip_selector: Variant = parts[1]
	if (clip_selector as String).is_valid_int():
		clip_selector = (clip_selector as String).to_int()

	if not MusicPlayer.set_music_clip(clip_selector):
		print("⚠️ MUSIC_CLIP could not be applied:", clip_selector)


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
