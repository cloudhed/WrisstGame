extends TileState

func enter() -> void:
	if not tile_ui.is_node_ready():
		await tile_ui.ready
	tile_ui.reparent_requested.emit(tile_ui)
	tile_ui.pivot_offset = Vector2.ZERO
	Events.tooltip_hide_requested.emit()

func on_gui_input(event: InputEvent) -> void:
	if not tile_ui.playable or tile_ui.disabled:
		return
	
	if event.is_action_pressed("left_mouse"):
		tile_ui.pivot_offset = tile_ui.get_global_mouse_position() - tile_ui.global_position
		transition_requested.emit(self, TileState.State.CLICKED)

func on_mouse_entered() -> void:
	if not tile_ui.playable or tile_ui.disabled:
		return
		
	Events.tile_tooltip_requested.emit(tile_ui.tile.tooltip_icon, tile_ui.tile.tooltip_text, tile_ui.tile.tooltip_source_label)
	
	# Find tooltip node (must be in group "tooltip")
	var tooltip := get_tree().get_first_node_in_group("tooltip")
	if tooltip:
		var tile_pos := tile_ui.global_position
		var tile_size := tile_ui.size
		var offset := Vector2(tile_size.x + 12, 0) # Move 12 pixels to the right of the tile
		tooltip.global_position = tile_pos + offset
	
func on_mouse_exited() -> void:
	if not tile_ui.playable or tile_ui.disabled:
		return
		
	Events.tooltip_hide_requested.emit()
