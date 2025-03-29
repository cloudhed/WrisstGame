extends Node2D

@export var default_bg: Texture2D
@export var forest_bg: Texture2D
@export var plains_bg: Texture2D
@export var mountains_bg: Texture2D
@export var shores_bg: Texture2D
@export var gradient: GradientTexture1D  # Reference to your daynight gradient

@onready var bg_sprite: Sprite2D = $CombatBGSprite
@onready var canvas_mod: CanvasModulate = $CanvasModulate
#@onready var whiteout_anim = $AnimationPlayer

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
	# Connect to Manager's signal for biome updates
	Manager.biome_updated.connect(_on_biome_updated)
	# Set initial background from biome info
	set_biome_background(Manager.combat_biome)
	# Apply day-night color modulation from the saved time
	apply_daynight_color()

func _on_biome_updated(new_biome: String) -> void:
	set_biome_background(new_biome)

func set_biome_background(biome_name: String) -> void:
	var texture = biome_textures.get(biome_name, default_bg)
	if texture:
		bg_sprite.texture = texture
	else:
		print("Warning: No texture for biome '%s', using default" % biome_name)
		bg_sprite.texture = default_bg
		
# New function to apply day-night color modulation
func apply_daynight_color() -> void:
	var time_data = Manager.last_time_of_day
	if time_data.has("hours") and time_data.has("minutes"):
		var hours: int = time_data["hours"]
		var minutes: int = time_data["minutes"]
		var total_minutes = hours * 60 + minutes
		var normalized_time = total_minutes / 1440.0  # 1440 minutes in a day
		# Triangle wave peaking at noon (like in your daynightCyclecolors.gd)
		var progress = sin(normalized_time * PI)
		# Sample the color from the gradient
		var mod_color: Color = gradient.gradient.sample(progress)
		canvas_mod.color = mod_color
	else:
		# Fallback if no time data was saved
		canvas_mod.color = Color(1, 1, 1)
