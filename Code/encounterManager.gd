extends Node2D

# 25/3 2025, Den cachear inte skog och berg, tror jag. Inte skog iaf av vad jag kunde se.

signal biome_updated(new_biome: String)

@export var combat_scene : PackedScene
@onready var PlayerDot = get_tree().get_root().get_node("overworld_node/PlayerDot")
var combat_biome: String = "Default" #player.highest_biome

var encounter_number : int = 100:
		set(value):
			encounter_number = value
			%EncounterLabel.text = str(value)

var player_last_position: Vector2 = Vector2(460,572) #(460,572)
var last_time_of_day: Dictionary = {} # Will hold {"hours": int, "minutes": int}
var last_time_period: String = "Day"  # Will store "Day" or "Night"

func _ready():
	randomize()
	encounter_number = randi_range(30,100) # (30,100)
	
func save_player_data(player):
	var biome_obj = player.get_current_biomes()
	if biome_obj:
		print("save_player_data: Highest biome detected:", biome_obj.biome_name)
		combat_biome = biome_obj.biome_name
	else:
		print("save_player_data: No biome detected, defaulting.")
		combat_biome = "Default"
		
	player_last_position = player.position
	
	# Fetch and store current time of day
	var time_node = get_tree().get_root().get_node("overworld_node/TimeOfDayControl")
	if time_node:
		if time_node.has_method("get_current_time"):
			last_time_of_day = time_node.get_current_time()
		if time_node.has_method("get_time_period"):
			last_time_period = time_node.get_time_period()
			
	emit_signal("biome_updated", combat_biome)
			
func change_scene():
	print("change_scene: Preparing to change to 'combat_scene'.")
	# Schedule the scene change to occur after the current frame
	get_tree().call_deferred("change_scene_to_packed", combat_scene)
	print("change_scene: Scene change to 'combat_scene' has been deferred.")
	# Reset the encounter number
	encounter_number = randi_range(30,100)
