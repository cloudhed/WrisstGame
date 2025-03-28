extends Node2D

signal biome_updated(new_biome: String)

@export var combat_scene: PackedScene
@onready var whiteout_anim = $AnimationPlayer

var combat_biome: String = "Default"
var encounter_number: int = 100:
	set(value):
		encounter_number = value
		%EncounterLabel.text = str(value)
var player_last_position: Vector2 = Vector2(460, 572)
var last_time_of_day: Dictionary = {}
var last_time_period: String = "Day"

func _ready() -> void:
	seed(randi())  # Better than randomize() for consistency
	encounter_number = randi_range(300, 600) #(30, 100)

func save_player_data(player: PlayerDot) -> void:
	var biome_obj = player.get_highest_priority_biome()
	combat_biome = biome_obj.biome_name if biome_obj else "Default"
	player_last_position = player.position
	
	var time_node = get_tree().get_root().get_node_or_null("overworld_node/TimeOfDayControl")
	if time_node:
		last_time_of_day = time_node.get_current_time() if time_node.has_method("get_current_time") else {}
		last_time_period = time_node.get_time_period() if time_node.has_method("get_time_period") else "Day"
	
	emit_signal("biome_updated", combat_biome)

func change_scene() -> void:
	whiteout_anim.play("fade_in")
#	get_tree().call_deferred("change_scene_to_packed", combat_scene)
	encounter_number = randi_range(30, 100)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"fade_in":
			get_tree().call_deferred("change_scene_to_packed", combat_scene)
			whiteout_anim.play("fade_out")
