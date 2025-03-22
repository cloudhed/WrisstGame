extends Node

@export var day_length_seconds: float = 30.0 # How many real-time seconds make one in-game day
@export var start_time_hours: int = 6
@export var start_time_minutes: int = 0

var current_time_seconds: float
var total_minutes_in_day: float
var last_displayed_minute: int = -1 # Tracking when to update display

func _ready():
	total_minutes_in_day = 24 * 60
	current_time_seconds = (start_time_hours * 60 + start_time_minutes) * (day_length_seconds / total_minutes_in_day)
	# Initialize last_displayed_minute based on the starting time
	last_displayed_minute = floor((current_time_seconds / day_length_seconds) * total_minutes_in_day)

func _process(delta):
	current_time_seconds += delta
	if current_time_seconds >= day_length_seconds:
		current_time_seconds -= day_length_seconds

	var current_minutes = (current_time_seconds / day_length_seconds) * total_minutes_in_day
	var hours = floor(current_minutes / 60)
	var minutes = floor(fmod(current_minutes, 60))
	
	# Only update the display if the minute has changed to a new 10-minute interval
	var displayed_minute = floor(minutes / 10.0) * 10
	if displayed_minute != last_displayed_minute:
		last_displayed_minute = displayed_minute

	# Format the time as HH:MM
	var time_string = "%02d:%02d" % [hours, displayed_minute]

	# Get the TimeLabel in the CanvasLayer and update its text
	var root = get_tree().get_root()
	var canvas_layer = root.get_node("overworld_node/CanvasLayer") # Adjust the path if your CanvasLayer is in a different location
	if canvas_layer:
		var time_label = canvas_layer.get_node("TimeLabel")
		if time_label and time_label is Label:
			time_label.text = "Time: " + time_string

func get_current_time() -> Dictionary:
	var current_minutes_float = (current_time_seconds / day_length_seconds) * total_minutes_in_day
	var hours = floor(current_minutes_float / 60)
	var minutes = floor(fmod(current_minutes_float, 60))
	return {"hours": hours, "minutes": minutes}
