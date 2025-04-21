extends TileState

func enter() -> void:
	if not tile_ui.is_node_ready():
		await tile_ui.ready
	tile_ui.reparent_requested.emit(tile_ui)
	tile_ui.pivot_offset = Vector2.ZERO
	Events.tooltip_hide_requested.emit()
	
	# Cache the particle nodes
	particles_bg = tile_ui.get_node("TileVFX/GPUParticles2D_HoverBG")
	particles_fg = tile_ui.get_node("TileVFX/GPUParticles2D_HoverFG")

	# Make sure they're off initially
	set_particles_emitting(false)
	
	
	

func on_gui_input(event: InputEvent) -> void:
	if not tile_ui.playable or tile_ui.disabled:
		return
	
	if event.is_action_pressed("left_mouse"):
		tile_ui.pivot_offset = tile_ui.get_global_mouse_position() - tile_ui.global_position
		transition_requested.emit(self, TileState.State.CLICKED)

func on_mouse_entered() -> void:
	if not tile_ui.playable or tile_ui.disabled:
		return

	set_particles_emitting(true)
	SFXPlayer.play(ui_sound)

	var tile_pos: Vector2 = tile_ui.global_position
	var tile_size: Vector2 = tile_ui.size

	Events.tile_tooltip_requested.emit(
		tile_ui.tile.tooltip_icon,
		tile_ui.tile.get_formatted_tooltip_text(),
		tile_ui.tile.tooltip_source_label,
		tile_pos,
		tile_size
	)
	
func on_mouse_exited() -> void:
	if not tile_ui.playable or tile_ui.disabled:
		return

	set_particles_emitting(false)

	Events.tooltip_hide_requested.emit()
