extends IslandBiome

# Change this variable for each biome area
@export var biome_name: String = "Forest"
@export var biome_priority = 3

#func _on_body_entered(body: Node) -> void:
#	if body.name == "PlayerDot":
#		if body is CharacterBody2D:
#			body.add_biome(self)  # Or however you update current_biomes
#			print("Entered biome:", self.biome_name)
		
#func _on_body_exited(body: Node) -> void:
#	if body.name == "PlayerDot":
#		if body is CharacterBody2D:
#			body.remove_biome(self)
#			print("Exited biome:", self.biome_name)

#		var debug_gui = get_tree().get_root().get_node("overworld_node/CanvasLayer")
#		if debug_gui:
#			debug_gui.set_biome(biome_name)
