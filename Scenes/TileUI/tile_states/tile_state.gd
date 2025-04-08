class_name TileState
extends Node

enum State {BASE, HOVER, CLICKED, DRAGGING, RELEASED, AIMING}

signal transition_requested(from: TileState, to: State)

@export var state: State
var tile_ui: TileUI
var particles_bg: GPUParticles2D
var particles_fg: GPUParticles2D

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

func set_particles_emitting(value: bool) -> void:
	if particles_bg:
		particles_bg.emitting = value
	if particles_fg:
		particles_fg.emitting = value
