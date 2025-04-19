class_name TileStateMachine
extends Node

@export var initial_state: TileState

var current_state: TileState
var states := {}

func init(tile: TileUI) -> void:
	for child in get_children():
		if child is TileState:
			states[child.state] = child
			child.transition_requested.connect(_on_transition_requested)
			child.tile_ui = tile
			
	if initial_state:
		initial_state.enter()
		current_state = initial_state
		
func on_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_input(event)
		
func on_gui_input(event: InputEvent) -> void:
	if current_state:
		current_state.on_gui_input(event)
		
func on_mouse_entered(event: InputEvent) -> void:
	if current_state:
		current_state.on_mouse_entered()
		
func on_mouse_exited(event: InputEvent) -> void:
	if current_state:
		current_state.on_mouse_exited()

func _on_transition_requested(from: TileState, to: TileState.State) -> void:
	if from != current_state:
		return
		
	var new_state: TileState = states[to]
	if not new_state:
		return
		
	if current_state:
		current_state.exit()
		
	new_state.enter()
	current_state = new_state
