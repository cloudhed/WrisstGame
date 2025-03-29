class_name TilePile
extends Resource

signal tile_pile_size_changed(tiles_amount)

@export var tiles: Array[Tile] = []

func empty() -> bool:
	return tiles.is_empty()


func draw_tile() -> Tile:
	var tile = tiles.pop_front()
	tile_pile_size_changed.emit(tiles.size())
	return tile


func add_tile(tile: Tile):
	tiles.append(tile)
	tile_pile_size_changed.emit(tiles.size())


func shuffle() -> void:
	tiles.shuffle()


func clear() -> void:
	tiles.clear()
	tile_pile_size_changed.emit(tiles.size())


func _to_string() -> String:
	var _tile_strings: PackedStringArray = []
	for i in range(tiles.size()):
		_tile_strings.append("%s: %s" % [i+1, tiles[i].id])
	return "\n".join(_tile_strings)
