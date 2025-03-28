extends TileState


func enter() -> void:
	tile_ui.color.color = Color.ORANGE
	tile_ui.state.text = "CLICKED"
	tile_ui.drop_point_detector.monitoring = true
	
func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		transition_requested.emit(self, TileState.State.DRAGGING)
