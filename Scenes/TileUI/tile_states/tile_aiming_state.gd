extends TileState

# const MOUSE_Y_SNAPBACK_THRESHOLD := 138

func enter() -> void:
	print("AIMING")
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		tile_ui.reparent(ui_layer) # Make sure it's in front
	tile_ui.targets.clear()
	Events.tile_aim_started.emit(tile_ui)


func exit() -> void:
	Events.tile_aim_ended.emit(tile_ui)


func on_input(event: InputEvent) -> void:
	var mouse_motion := event is InputEventMouseMotion
#	var mouse_at_bottom := tile_ui.get_global_mouse_position().y > MOUSE_Y_SNAPBACK_THRESHOLD
	
	#adding back the dragging, hoping that it fixes the snapback (EDIT: Nope, still snaps back.)
	if mouse_motion:
		tile_ui.global_position = tile_ui.get_global_mouse_position() - tile_ui.pivot_offset
		
				# Update tooltip position to follow tile
		var tooltip := get_tree().get_first_node_in_group("tooltip")
		if tooltip:
			var screen_size := get_viewport().get_window().size
			var tile_pos := tile_ui.global_position
			var tile_size := tile_ui.size
			
			var offset := Vector2(tile_ui.size.x + 12, 0)
			
			# Flip to left if too close to screen edge
			if tile_pos.x + tile_size.x + tooltip.size.x + 12 > screen_size.x:
				offset = Vector2(-tooltip.size.x - 12, 0)
				
			tooltip.global_position = tile_ui.global_position + offset
	
	if event.is_action_pressed("right_mouse"): #this WAS if (mouse_motion and mouse_at_bottom) or event.is_action_pressed("right_mouse"):
		SFXPlayer.play(ui_sound)
		transition_requested.emit(self, TileState.State.BASE)
	elif event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse"):
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, TileState.State.RELEASED)
