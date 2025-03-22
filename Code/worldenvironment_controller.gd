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

		# Define the hours for daytime and nighttime
#		var daytime_start_hour = 4  # Example: 7 AM
#		var daytime_end_hour = 8 # Example: 7 PM

#		if hours >= daytime_start_hour and hours < daytime_end_hour:
#			# Daytime settings
#			world_environment.environment.adjustment_enabled = true
#			world_environment.environment.adjustment_brightness = 1.0
#			world_environment.environment.adjustment_contrast = 1.0
#			world_environment.environment.adjustment_saturation = 1.0
#			world_environment.environment.glow_enabled = true
#			world_environment.environment.glow_intensity = 0.0

#		else:
			# Nighttime settings
#			world_environment.environment.adjustment_enabled = true
#			world_environment.environment.adjustment_brightness = 1.0
#			world_environment.environment.adjustment_contrast = 1.0
#			world_environment.environment.adjustment_saturation = 1.0
#			world_environment.environment.glow_enabled = true
#			world_environment.environment.glow_intensity = 1.7
			# You might want to add a slight blueish tint at night using color correction
			# Example of a subtle color correction (you might need a color correction texture for more complex effects)
			# world_environment.color_correction = Color(0.1, 0.1, 0.2, 0.0) # This might not work directly, LUT is better for this
#		else:
			# Default settings (in case the time is somehow invalid)
#			world_environment.adjustment_enabled = false

# You might want to add functions for dawn and dusk later for smoother transitions
