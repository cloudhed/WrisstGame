extends TileState

const DRAG_MINIMUM_THRESHOLD := 0.05

var minimum_drag_time_elapsed := false


func enter() -> void:
	print("DRAGGING") #debug to check DRAGGING
	tile_ui.set_motion_suspended(true)
	
	set_particles_emitting(false) # Dragging = no selection effect
	
	var ui_layer := get_tree().get_first_node_in_group("ui_layer")
	if ui_layer:
		tile_ui.preserve_global_position_on_reparent(ui_layer)
	
	Events.tile_drag_started.emit(tile_ui)
		
	minimum_drag_time_elapsed = false
	var threshold_timer := get_tree().create_timer(DRAG_MINIMUM_THRESHOLD, false)
	threshold_timer.timeout.connect(func(): minimum_drag_time_elapsed = true)

func exit() -> void:
	tile_ui.set_motion_suspended(false)
	Events.tile_drag_ended.emit(tile_ui)

func on_input(event: InputEvent) -> void:
	var single_targeted: bool = tile_ui.tile.is_single_targeted()
	var mouse_motion: bool = event is InputEventMouseMotion
	var cancel: bool = event.is_action_pressed("right_mouse")
	var confirm: bool = event.is_action_released("left_mouse") or event.is_action_pressed("left_mouse")

	if single_targeted and mouse_motion and tile_ui.targets.size() > 0:
		transition_requested.emit(self, TileState.State.AIMING)
		return

	if mouse_motion:
		tile_ui.global_position = tile_ui.get_global_mouse_position() - tile_ui.pivot_offset

		# Let Tooltip.gd handle positioning instead
		var tile_pos: Vector2 = tile_ui.global_position
		var tile_size: Vector2 = tile_ui.size

		Events.tile_tooltip_requested.emit(
			tile_ui.tile.tooltip_icon,
			tile_ui.tile.get_formatted_tooltip_text(),
			tile_ui.tile.tooltip_source_label,
			tile_pos,
			tile_size
		)

	if cancel:
		SFXPlayer.play(ui_sound)
		transition_requested.emit(self, TileState.State.BASE)
	elif minimum_drag_time_elapsed and confirm:
		get_viewport().set_input_as_handled()
		transition_requested.emit(self, TileState.State.RELEASED)
