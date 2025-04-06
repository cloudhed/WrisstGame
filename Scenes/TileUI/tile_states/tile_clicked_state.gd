extends TileState


func enter() -> void:
	tile_ui.drop_point_detector.monitoring = true
	tile_ui.original_index = tile_ui.get_index()
	
func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transition_requested.emit(self, TileState.State.DRAGGING)
