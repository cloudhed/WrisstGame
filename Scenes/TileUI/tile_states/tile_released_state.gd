extends TileState

var played: bool

func enter() -> void:
	
	played = false
	
	if not tile_ui.targets.is_empty():
		played = true
		print("play tile for target:", tile_ui.targets)

		
func on_input(_event: InputEvent) -> void:
	if played:
		return
		
	transition_requested.emit(self, TileState.State.BASE)
