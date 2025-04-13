# meta-name: Tile Logic
# meta-description: What happens when a tile is played.
extends Tile

@export var optional_sound: AudioStream


func apply_effects(targets: Array[Node]) -> void:
	print("I did play the tile!")
	print("Targets: %s" % targets)
