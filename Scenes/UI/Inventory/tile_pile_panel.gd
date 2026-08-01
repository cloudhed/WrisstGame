class_name TilePilePanel
extends PanelContainer

## The inventory's right-hand column: a preview of the tile pile the player's
## current gear produces.
##
## This mirrors combat state rather than inventory state, so it lives apart from
## inventory_screen.gd. Its tiles come from PileManager.get_preview_tiles(), the
## same function get_logical_deck() builds the real combat deck from, so the two
## cannot drift.

const TILE_GRID_CARD_SCENE_PATH := "res://Scenes/TileUI/tile_grid_card.tscn"

@onready var current_tiles_label: Label = %CurrentTilesLabel
@onready var pile_power_label: Label = %PilePowerLabel
@onready var tile_grid: GridContainer = %TileGrid

var _tile_grid_card_scene: PackedScene = null


## Loaded on first use rather than preloaded: GameUI is an autoload, and the
## tile card scene should not be in memory until the player opens the screen.
func _get_tile_grid_card_scene() -> PackedScene:
	if _tile_grid_card_scene == null:
		_tile_grid_card_scene = load(TILE_GRID_CARD_SCENE_PATH) as PackedScene
		if _tile_grid_card_scene == null:
			push_error("❌ Failed to load tile grid card scene: " + TILE_GRID_CARD_SCENE_PATH)
	return _tile_grid_card_scene


func refresh() -> void:
	for child in tile_grid.get_children():
		tile_grid.remove_child(child)
		child.queue_free()

	# Typed explicitly: pile_manager.gd has no class_name, so the analyzer sees
	# the autoload as a bare Node and cannot infer the return type.
	var tile_pile: Array[Tile] = PileManager.get_preview_tiles()

	tile_pile.sort_custom(func(a: Tile, b: Tile) -> bool:
		return a.effect_amount > b.effect_amount
	)

	var card_scene := _get_tile_grid_card_scene()
	if card_scene != null:
		for tile in tile_pile:
			var card = card_scene.instantiate()
			card.tile = tile
			tile_grid.add_child(card)

	# Set outside the card loop, so an empty pile reports 0 rather than leaving
	# the previous count on screen.
	current_tiles_label.text = "Tiles in Pile: %d" % tile_pile.size()
	pile_power_label.text = "Pile Power: %.1f" % ItemStatFormatter.calculate_pile_power(tile_pile)
