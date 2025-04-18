class_name DialogLineSpawner
extends Control

@export var narration_container: VBoxContainer
@export var speech_container: VBoxContainer

var active_lines: Array[Control] = []


func spawn_chunk(chunk: Dictionary, speaker: String, character_map: Dictionary) -> void:
#	print("💥 Spawning chunk of type:", chunk.get("type", "???"))
#	print("CHUNK DATA:", chunk)

	var node: Control
	var chunk_type: String = chunk.get("type", "")
	var chunk_text: String = chunk.get("text", "[Missing Text]")

	match chunk_type:
		"speech":
			var speech_scene = preload("res://Scenes/UI/speech_bubble.tscn")
			node = speech_scene.instantiate()

			if node == null or not node.has_method("set_text"):
				push_error("❌ Failed to instantiate or setup SpeechBubble!")
				return

			var character: CharacterResource = character_map.get(speaker, null)
			if character:
				node.set_text(
					chunk_text,
					character.color,
					character.speech_bubble_color,
					character.speech_bubble_font,
					#character.speech_bubble_font_size,
					#character.speech_bubble_style
				)
			else:
				node.set_text(chunk_text)

			if speech_container == null:
				push_error("❌ speech_container is not assigned!")
				return

			speech_container.add_child(node)
			active_lines.append(node)
#			print("📤 SpeechBubble added to speech_container")

		"narration":
			var narration_scene = preload("res://Scenes/UI/narration_box.tscn")
			node = narration_scene.instantiate()

			if node == null or not node.has_method("set_text"):
				push_error("❌ Failed to instantiate or setup NarrationBox!")
				return

			node.set_text(chunk_text)

			if narration_container == null:
				push_error("❌ narration_container is not assigned!")
				return

			narration_container.add_child(node)
			active_lines.append(node)
#			print("📖 NarrationBox added to narration_container")

		_:
			push_warning("⚠️ Unknown chunk type: " + str(chunk_type))
			return

	# Finalize node after it's added
	await node.ready
	node.visible = true

	# Debug output
#	print("🧭 Spawned node:", node.name)
#	print("🗺️ Global position:", node.global_position)
#	print("📐 Node size:", node.size)

#	if node.has_node("Panel"):
#		var panel = node.get_node("Panel")
#		print("🪟 Panel size:", panel.size)
#		if panel.has_node("Text"):
#			print("📝 Label size:", panel.get_node("Text").size)
#		elif panel.has_node("BubbleText"):
#			print("📝 Label size:", panel.get_node("BubbleText").size)

	node.queue_redraw()
	active_lines.append(node)
#	print("✅ Chunk added to correct container")


func clear_lines():
#	print("🧹 Clearing", active_lines.size(), "active lines")
	for node in active_lines:
		if node and is_instance_valid(node):
#			print("❌ Removing:", node.name, node)
			node.queue_free()
#		else:
#			print("⚠️ Skipped invalid or already-freed node:", node)
	active_lines.clear()
