extends Node

@export var amb_audio_player: AudioStreamPlayer
@onready var time_of_day_control: Node = get_tree().get_root().get_node("overworld_node/TimeOfDayControl")

var current_state: String = "Day"

func _ready():
	print("DEBUG: it is currently ", current_state)

func _process(delta):
#	print("DEBUG: _process is running")
	if time_of_day_control and time_of_day_control.has_method("get_time_period"):
		var current_period = time_of_day_control.get_time_period()
		if current_period != current_state:
			current_state = current_period
			update_amb_for_scene()
			
			if current_period == "Day":
				print("DEBUG: Playing: SoundAmbMapDay")
				# Add code to play day ambience
			elif current_period == "Night":
				print("DEBUG: Playing: SoundAmbMapNight")
				# Add code to play day ambience
func update_amb_for_scene():
	var current_amb_music = "SoundAmbMap" + current_state
	amb_audio_player["parameters/switch_to_clip"] = current_amb_music
