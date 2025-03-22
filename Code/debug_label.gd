extends CanvasLayer

@onready var debug_label = $DebugLabel

func set_biome(biome_name: String) -> void:
	debug_label.text = biome_name
	
#func _ready():
#	set_biome("Highest Biome: Shores\nAll Overlapping Biomes: (none)")

# Remove or comment out the _process function
# func _process(delta):
#     debug_label.text = "Biome: " + get_current_biome()
#     
# func get_current_biome() -> String:
#     return "Shores"
