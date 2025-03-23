extends Node

@onready var world_environment: WorldEnvironment = get_node("WorldEnvironment") # Adjust this path if your WorldEnvironment is in a different location
@onready var time_of_day_control: Node = get_node("../TimeOfDayControl") # Adjust this path if your TimeOfDayControl is in a different location

func _process(delta):
	if world_environment and time_of_day_control and time_of_day_control.has_method("get_current_time"):
		var current_time = time_of_day_control.get_current_time()
		var hours = current_time.hours
		var minutes = current_time.minutes
#		print("DEBUG: Time is:", hours)

		var total_minutes_in_day = hours * 60 + minutes
		var normalized_time = total_minutes_in_day / 1440.0
		var progress = (cos(normalized_time * 2 * PI) + 1) / 2
		
		world_environment.environment.glow_enabled = true
		world_environment.environment.glow_intensity = progress * 4.0
