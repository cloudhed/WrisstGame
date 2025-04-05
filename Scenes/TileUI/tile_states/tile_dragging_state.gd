extends TileState

const DRAG_MINIMUM_THRESHOLD := 0.05

var minimum_drag_time_elapsed := false


func enter() -> void:
	print("DRAGGING") #debug to check DRAGGING
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		tile_ui.reparent(ui_layer)
	
	Events.tile_drag_started.emit(tile_ui)
		
	minimum_drag_time_elapsed = false
	var threshold_timer := get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(func(): minimum_drag_time_elapsed = true)

func exit() -> void:
	Events.tile_drag_ended.emit(tile_ui)

func on_input(event: InputEvent) -> void:
	var single_targeted := tile_ui.tile.is_single_targeted()
	var mouse_motion := event is InputEventMouseMotion
	var cancel = event.is_action_pressed("right_mouse")
	var confirm = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")
	
	if single_targeted and mouse_motion and tile_ui.targets.size() > 0:
		transition_requested.emit(self, TileState.State.AIMING)
		return

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
	
	if cancel:
		transition_requested.emit(self, TileState.State.BASE)
	elif minimum_drag_time_elapsed and confirm:
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, TileState.State.RELEASED)
