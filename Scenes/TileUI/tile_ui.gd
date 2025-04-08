class_name TileUI
extends Control

signal reparent_requested(which_tile_ui: TileUI)

@export var tile: Tile : set = _set_tile
@export var char_stats: CharacterStats : set = _set_char_stats

#@onready var background: Panel = $Background
@onready var icon: TextureRect = $Icon
@onready var cost: Label = $Cost
@onready var effect_amount: Label = $Amount #This is added by me

@onready var drop_point_detector: Area2D = $DropPointDetector
@onready var tile_state_machine: TileStateMachine = $TileStateMachine as TileStateMachine
@onready var targets: Array[Node] = []

var original_index := 0
var parent_hand: Hand
var playable := true : set = _set_playable
var disabled := false

func _ready() -> void:
	Events.tile_aim_started.connect(_on_tile_drag_or_aiming_started)
	Events.tile_drag_started.connect(_on_tile_drag_or_aiming_started)
	Events.tile_drag_ended.connect(_on_tile_drag_or_aiming_ended)
	Events.tile_aim_ended.connect(_on_tile_drag_or_aiming_ended)
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
	icon.texture = tile.icon
	
	#this is START for showing tile effect amount on the tile, will prolly comment out
	if tile.effect_amount > 0:
		effect_amount.text = str(tile.effect_amount)
		effect_amount.visible = true
	else:
		effect_amount.visible = false
		#this is END for showing tile effect amount
		
#	amount.text = str(tile.amount) if tile.amount > 0 else "" #hide string if 0
#	amount.text = str(tile.amount) old version
	
#	background.texture = tile.background


func setup_tile_ui(_player_node: Node, _char_stats: CharacterStats):
	player_node = _player_node
	char_stats = _char_stats


func _set_playable(value: bool) -> void:
	playable = value
	if not playable:
		cost.add_theme_color_override("font_color", Color.FIREBRICK)
		icon.modulate = Color(1, 1, 1, 0.5)
	else:
		cost.remove_theme_color_override("font_color")
		icon.modulate = Color(1, 1, 1, 1)



func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	char_stats.stats_changed.connect(_on_char_stats_changed)


var player_node: Node


func _on_drop_point_detector_area_entered(area: Area2D) -> void:
	if not targets.has(area):
		targets.append(area)

func _on_drop_point_detector_area_exited(area: Area2D) -> void:
	targets.erase(area)


func _on_tile_drag_or_aiming_started(used_tile: TileUI) -> void:
	if used_tile == self:
		return
		
	disabled = true


func _on_tile_drag_or_aiming_ended(_tile: TileUI) -> void:
	disabled = false
	self.playable = char_stats.can_play_tile(tile)


func _on_char_stats_changed() -> void:
	self.playable = char_stats.can_play_tile(tile)
