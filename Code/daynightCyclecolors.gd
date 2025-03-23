extends CanvasModulate

@export var gradient:GradientTexture1D
@onready var time_of_day_control: Node = get_node("../TimeOfDayControl") # Adjust path if needed

func _process(_delta):
	if time_of_day_control and time_of_day_control.has_method("get_current_time"):
		var current_time = time_of_day_control.get_current_time()
		var hours = current_time.hours
		var minutes = current_time.minutes
		var total_minutes_in_day = hours * 60 + minutes

		# Calculate normalized time (0.0 to 1.0 over 24 hours)
		var normalized_time = total_minutes_in_day / 1440.0  # 1440 minutes in a day
		# Create a triangle wave that peaks at noon (normalized_time == 0.5) and is 0 at midnight:
#		var progress = 1.0 - abs(normalized_time - 0.5) * 2.0
		var progress = sin(normalized_time * PI)

#		if total_minutes_in_day < 12 * 60: # From 00:00 to 11:59 (before noon)
#			progress = float(total_minutes_in_day) / (12 * 60)
#		else: # From 12:00 to 23:59 (noon to before midnight)
#			progress = 1.0 - float(total_minutes_in_day - 12 * 60) / (12 * 60)

		if gradient:
			self.color = gradient.gradient.sample(progress)
