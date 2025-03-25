extends Node2D

@export var default_bg: Texture2D
@export var forest_bg: Texture2D
@export var plains_bg: Texture2D
@export var mountains_bg: Texture2D
@export var shores_bg: Texture2D

@onready var bg_sprite: Sprite2D = $CombatBGSprite
@onready var whiteout_anim = $AnimationPlayer

var biome_textures: Dictionary = {}

func _ready() -> void:
# Populate dictionary once
	biome_textures = {
		"Forest": forest_bg,
		"Plains": plains_bg,
		"Mountains": mountains_bg,
		"Shores": shores_bg,
		"Default": default_bg
	}
	# Connect signal directly
	Manager.biome_updated.connect(_on_biome_updated)
	# Set initial background
	set_biome_background(Manager.combat_biome)

func _on_biome_updated(new_biome: String) -> void:
	set_biome_background(new_biome)

func set_biome_background(biome_name: String) -> void:
	var texture = biome_textures.get(biome_name, default_bg)
	if texture:
		bg_sprite.texture = texture
	else:
		print("Warning: No texture for biome '%s', using default" % biome_name)
		bg_sprite.texture = default_bg
