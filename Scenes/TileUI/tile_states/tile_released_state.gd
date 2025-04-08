extends TileState

var played: bool

func enter() -> void:
	
	played = false
	
	if not tile_ui.targets.is_empty():
		Events.tooltip_hide_requested.emit()
		played = true
		tile_ui.play()
		print("play tile for target:", tile_ui.targets)
	else:
		set_particles_emitting(true) # Maybe re-highlight on release if not played?
		

		
func on_input(_event: InputEvent) -> void:
	if played:
		return
		
	transition_requested.emit(self, TileState.State.BASE)
