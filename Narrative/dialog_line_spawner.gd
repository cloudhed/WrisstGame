class_name DialogLineSpawner
extends Control

@export var container: VBoxContainer

var active_lines: Array[Control] = []

func spawn_chunk(chunk: Dictionary, speaker: String, character_map: Dictionary) -> void:
	print("💥 Spawning chunk of type:", chunk.get("type", "???"))
	print("CHUNK DATA:", chunk)

	var node: Control
	var chunk_type: String = chunk.get("type", "")
	var chunk_text: String = chunk.get("text", "[Missing Text]")

	match chunk_type:
		"speech":
			var speech_scene = preload("res://Scenes/UI/speech_bubble.tscn")
			node = speech_scene.instantiate()

			if node == null:
				push_error("❌ SpeechBubble instancing failed!")
				return
			else:
				print("✅ SpeechBubble node instanced")

			if not node.has_method("set_text"):
				push_error("❌ SpeechBubble is missing `set_text()` method!")
				return

			var character: CharacterResource = character_map.get(speaker, null)
			if character:
				node.set_text(
					chunk_text,
					character.color,
					character.speech_bubble_color,
					character.speech_bubble_font
				)
			else:
				node.set_text(chunk_text)

		"narration":
			var narration_scene = preload("res://Scenes/UI/narration_box.tscn")
			node = narration_scene.instantiate()

			if node == null:
				push_error("❌ NarrationBox instancing failed!")
				return
			else:
				print("✅ NarrationBox node instanced")

			if not node.has_method("set_text"):
				push_error("❌ NarrationBox is missing `set_text()` method!")
				return

			node.set_text(chunk_text)

		_:
			push_warning("⚠️ Unknown chunk type: " + str(chunk_type))
			return

	# Final step: Add to container if valid
	if node:
		if container == null:
			push_error("❌ container (VBoxContainer) is null! Cannot add node.")
			return
		else:
			print("📦 Container is valid:", container.name)

		# Add before awaiting ready
		container.add_child(node)
		await node.ready

		node.visible = true

		print("🧭 Spawned node:", node.name)
		print("📦 Container now has:", container.get_child_count(), "children")
		print("🗺️ Global position:", node.global_position)
		print("📐 Node size:", node.size)

		if node.has_node("Panel"):
			var panel = node.get_node("Panel")
			print("🪟 Panel size:", panel.size)
			if panel.has_node("Text"):
				print("📝 Label size:", panel.get_node("Text").size)
			elif panel.has_node("BubbleText"):
				print("📝 Label size:", panel.get_node("BubbleText").size)

		node.queue_redraw()
		container.queue_redraw()
		container.queue_sort()

		active_lines.append(node)
		print("✅ Chunk added to container")
	else:
		push_error("❌ Node was never instantiated.")


func clear_lines():
	print("🧹 Clearing", active_lines.size(), "active lines")
	for node in active_lines:
		if node:
			node.queue_free()
	active_lines.clear()
