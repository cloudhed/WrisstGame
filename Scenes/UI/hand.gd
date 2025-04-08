class_name Hand
extends VBoxContainer

@export var char_stats: CharacterStats

@onready var tile_ui := preload("res://Scenes/TileUI/tile_ui.tscn")

var player_node: Node  # 👈 this will be assigned from CombatUI.gd
#var tiles_played_this_turn := 0

#func _ready() -> void:
#	Events.tile_played.connect(_on_tile_played)


func add_tile(tile: Tile) -> void:
	var new_tile_ui := tile_ui.instantiate()
	add_child(new_tile_ui)
	
	new_tile_ui.reparent_requested.connect(_on_tile_ui_reparent_requested)
	new_tile_ui.tile = tile
	new_tile_ui.parent_hand = self
	
	new_tile_ui.setup_tile_ui(player_node, char_stats)


func discard_tile(tile: TileUI) -> void:
	tile.queue_free()


func disable_hand() -> void:
	for tile in get_children():
		tile.disabled = true

#	for child in get_children():a
#		var tile_ui := child as TileUI
#		tile_ui.parent = self
#		tile_ui.reparent_requested.connect(_on_tile_ui_reparent_requested)


#func _on_tile_played(_tile: Tile) -> void:
#	tiles_played_this_turn += 1


func _on_tile_ui_reparent_requested(child: TileUI) -> void:
#	tile.disabled = true
	child.reparent(self)
	var new_index := clampi(child.original_index, 0, get_child_count())
	move_child.call_deferred(child, new_index)
	child.set_deferred("disabled", false)
