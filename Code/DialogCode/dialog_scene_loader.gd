extends Node
class_name DialogSceneLoader

signal hotspot_triggered(target_id: String)

# Call this to load everything from a DialogSceneResource
func load_scene(dialog_manager: Node, data: DialogSceneResource, 
				zone_container: Node2D, mist_container: Node2D, 
				background: TextureRect, ambience_player: AudioStreamPlayer,
				character_map: Dictionary, out_slide_deck: Callable, 
				out_flags: Callable) -> void:

	clear_container(zone_container)
	clear_container(mist_container)

	if data.zone_scene:
		var zone_instance: Node2D = data.zone_scene.instantiate()
		zone_container.add_child(zone_instance)
		zone_instance.position = Vector2.ZERO

		# ✅ IMPORTANT: Assign dialog_manager if this is a ZoneScene
		if zone_instance is ZoneScene:
			(zone_instance as ZoneScene).dialog_manager = dialog_manager

		# 🔌 Reconnect hotspot signals directly here
		for hotspot in zone_instance.get_children():
			if hotspot is Hotspot:
				hotspot.hotspot_triggered.connect(
					func(target_id): emit_signal("hotspot_triggered", target_id)
				)
				print("✅ Connected hotspot:", hotspot.name)
	else:
		background.texture = data.background_texture

	if data.music:
		MusicPlayer.play(data.music, true)

	if data.ambience:
		ambience_player.stream = data.ambience
		ambience_player.play()

	for flag_name in data.flags_set_on_start:
		out_flags.call()[flag_name] = data.flags_set_on_start[flag_name]

	out_slide_deck.call(data.slide_deck)
	if not data.slide_deck:
		print("⚠️ WARNING: No SlideDeck assigned in DialogSceneResource.")

	character_map.clear()
	for entry in data.characters:
		if entry is CharacterEntry:
			character_map[entry.id] = entry.character_resource

	print("✅ Dialog scene loaded.")
	

func clear_container(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
