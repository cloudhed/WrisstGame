extends Node

# Tile-related events
#tile aim
signal tile_aim_started(tile_ui: TileUI)
signal tile_aim_ended(tile_ui: TileUI)
#tile played
signal tile_played(tile: Tile)

#combat text log
signal combat_text_emitted(message: String)
