extends Node2D

@export var default_bg: Texture2D
@export var forest_bg: Texture2D
@export var plains_bg: Texture2D
@export var mountains_bg: Texture2D
@export var shores_bg: Texture2D

@onready var bg_sprite: Sprite2D = $CombatBGSprite

func _ready():
	# Connect to the biome_updated signal from Manager (your autoload)
	if Manager.has_signal("biome_updated"):
		Manager.connect("biome_updated", _on_biome_updated)
	# Also set the background based on current value
	set_biome_background(Manager.combat_biome)

func _on_biome_updated(new_biome: String) -> void:
	set_biome_background(new_biome)

func set_biome_background(biome_name: String):
	match biome_name:
		"Forest":
			bg_sprite.texture = forest_bg
		"Plains":
			bg_sprite.texture = plains_bg
		"Mountains":
			bg_sprite.texture = mountains_bg
		"Shores":
			bg_sprite.texture = shores_bg
		_:  # Includes "Default" and any unexpected values
			bg_sprite.texture = default_bg
#			if biome_name != "Default":
#				printerr("Unknown biome '%s', using default background" % biome_name)
func _exit_tree():
	if Manager.is_connected("biome_updated", _on_biome_updated):
		Manager.disconnect("biome_updated", _on_biome_updated)
