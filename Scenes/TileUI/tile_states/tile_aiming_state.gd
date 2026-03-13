extends TileState

# const MOUSE_Y_SNAPBACK_THRESHOLD := 138

func enter() -> void:
	print("AIMING")
	tile_ui.set_motion_suspended(true)
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		tile_ui.preserve_global_position_on_reparent(ui_layer) # Make sure it's in front
	tile_ui.targets.clear()
	Events.tile_aim_started.emit(tile_ui)


func exit() -> void:
	tile_ui.set_motion_suspended(false)
	Events.tile_aim_ended.emit(tile_ui)


func on_input(event: InputEvent) -> void:
	var mouse_motion: bool = event is InputEventMouseMotion

	if mouse_motion:
		tile_ui.global_position = tile_ui.get_global_mouse_position() - tile_ui.pivot_offset

		# Send tooltip info to Tooltip.gd — it will handle positioning now
		var tile_pos: Vector2 = tile_ui.global_position
		var tile_size: Vector2 = tile_ui.size

		Events.tile_tooltip_requested.emit(
			tile_ui.tile.tooltip_icon,
			tile_ui.tile.get_formatted_tooltip_text(),
			tile_ui.tile.tooltip_source_label,
			tile_pos,
			tile_size
		)

	if event.is_action_pressed("right_mouse"):
		SFXPlayer.play(ui_sound)
		transition_requested.emit(self, TileState.State.BASE)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, TileState.State.RELEASED)
