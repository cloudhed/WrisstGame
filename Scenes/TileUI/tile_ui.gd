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
@onready var motion_presenter = $TileMotionPresenter
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
	motion_presenter.setup(self)
	tile_state_machine.init(self)


func _process(delta: float) -> void:
	motion_presenter.process_motion(delta)
	
func _input(event: InputEvent) -> void:
	tile_state_machine.on_input(event)
	
	
func play() -> void:
	if not tile or not char_stats:
		return
	
	if char_stats.stamina < tile.cost:
		print("[DEBUG] Not enough stamina to play this tile.")
		return
	
	if player_node is CombatPlayer and player_node.has_scheduled_end_turn:
		print("[DEBUG] Turn already ending — ignoring tile play.")
		return
	
	tile.play(targets, char_stats)

	# 🔧 Force update stats manually in case the signal doesn't emit fast enough
	if player_node is CombatPlayer:
		player_node.update_stats()

	queue_free()
	
	
func _on_gui_input(event: InputEvent) -> void:
	tile_state_machine.on_gui_input(event)

func _on_mouse_entered() -> void: 
	tile_state_machine.on_mouse_entered(null) #HERE'S WHERE IT POINTS THE CRASH and says: Invalid call. Nonexistent function 'on_mouse_entered' in base 'Node (TileStateMachine)'.
	
func _on_mouse_exited() -> void:
	tile_state_machine.on_mouse_exited(null)


func set_hover_motion(active: bool, mouse_global_pos := Vector2.ZERO) -> void:
	motion_presenter.set_hover_motion(active, mouse_global_pos)


func set_motion_suspended(active: bool) -> void:
	motion_presenter.set_motion_suspended(active)


func update_hover_motion_mouse(mouse_global_pos: Vector2) -> void:
	motion_presenter.update_hover_motion_mouse(mouse_global_pos)


func preserve_global_position_on_reparent(new_parent: Node) -> void:
	motion_presenter.preserve_global_position_on_reparent(new_parent)


func is_hover_motion_active() -> bool:
	return motion_presenter.is_hover_active()

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
		set_motion_suspended(true)
		return
		
	disabled = true


func _on_tile_drag_or_aiming_ended(_tile: TileUI) -> void:
	disabled = false
	self.playable = char_stats.can_play_tile(tile)
	set_motion_suspended(false)


func _on_char_stats_changed() -> void:
	self.playable = char_stats.can_play_tile(tile)
