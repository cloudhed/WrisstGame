class_name TileUI
extends Control

signal reparent_requested(which_tile_ui: TileUI)

@export var tile: Tile : set = _set_tile
@export var char_stats: CharacterStats

#@onready var background: Panel = $Background
@onready var icon: TextureRect = $Icon
@onready var cost: Label = $Cost
#@onready var amount: Label = $Amount


@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var tile_state_machine: TileStateMachine = $TileStateMachine as TileStateMachine
@onready var targets: Array[Node] = []

func _ready() -> void:
	tile_state_machine.init(self)
	
func _input(event: InputEvent) -> void:
	tile_state_machine.on_input(event)
	
	
func play() -> void:
	if not tile:
		return
	
	tile.play(targets, char_stats)
	queue_free()
	
	
func _on_gui_input(event: InputEvent) -> void:
	tile_state_machine.on_gui_input(event)

func _on_mouse_entered() -> void:
	tile_state_machine.on_mouse_entered(null)
	
func _on_mouse_exited() -> void:
	tile_state_machine.on_mouse_exited(null)

func _set_tile(value: Tile) -> void:
	if not is_node_ready():
		await ready
	
	tile = value
	cost.text = str(tile.cost)
#	amount.text = str(tile.amount) if tile.amount > 0 else "" #hide string if 0
#	amount.text = str(tile.amount) old version
	icon.texture = tile.icon
#	background.texture = tile.background

func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)

func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)
