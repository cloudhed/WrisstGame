extends IslandBiome

# Change this variable for each biome area
@export var biome_name: String = "Shores"
@export var biome_priority = 1

#func _on_body_entered(body: Node2D) -> void:
#	if body.name == "PlayerDot":
#		var debug_gui = get_tree().get_root().get_node("overworld_node/CanvasLayer")
#		if debug_gui:
#			debug_gui.set_biome(biome_name)
