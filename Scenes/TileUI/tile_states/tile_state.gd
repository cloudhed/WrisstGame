class_name TileState
extends Node

enum State {BASE, HOVER, CLICKED, DRAGGING, RELEASED}

signal transition_requested(from: TileState, to: State)

@export var state: State
var tile_ui: TileUI

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func on_input(_event: InputEvent) -> void:
	pass
	
func on_gui_input(_event: InputEvent) -> void:
	pass
	
func on_mouse_entered() -> void:
	pass
	
func on_mouse_exited() -> void:
	pass
