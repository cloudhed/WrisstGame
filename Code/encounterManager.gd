extends Node2D

@export var combat_scene : PackedScene
@onready var PlayerDot = get_tree().get_root().get_node("overworld_node/PlayerDot")
var combat_biome : Node = null

var encounter_number : int = 100:
		set(value):
			encounter_number = value
			%EncounterLabel.text = str(value)

var player_last_position: Vector2 = Vector2(460,572)

func _ready():
	randomize()
	encounter_number = randi_range(25,50)

func change_scene():
	get_tree().change_scene_to_packed(combat_scene)
	encounter_number = randi_range(25,50)
	
func save_player_data(player):
	combat_biome = player.get_current_biomes() #this doesn't work. help me, ChatGPT
	player_last_position = player.position
