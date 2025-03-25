extends Node

@export var day_length_seconds: float = 120.0 # How many real-time seconds make one in-game day
@export var start_time_hours: int = 6 # Starting hour
@export var start_time_minutes: int = 0 # Starting minute

var current_time_seconds: float
var total_minutes_in_day: float = 24 * 60
# var total_minutes_in_day: float
var last_displayed_minute: int = -1 # Tracking when to update display

func _ready():
	total_minutes_in_day = 24 * 60
	current_time_seconds = (start_time_hours * 60 + start_time_minutes) * (day_length_seconds / total_minutes_in_day)
	# Initialize last_displayed_minute based on the starting time
	last_displayed_minute = floor((current_time_seconds / day_length_seconds) * total_minutes_in_day)

# Suppose encounterManager is autoloaded as Manager
	if Manager.last_time_of_day.size() > 0:
		var hours = Manager.last_time_of_day["hours"]
		var minutes = Manager.last_time_of_day["minutes"]
		set_current_time(hours, minutes)

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
		var time_string = "%02d:%02d" % [hours, displayed_minute]
		var time_label = get_tree().get_root().get_node("overworld_node/CanvasLayer/TimeLabel")
		if time_label and time_label is Label:
			time_label.text = "Time: " + time_string

func get_current_time() -> Dictionary:
	var current_minutes_float = (current_time_seconds / day_length_seconds) * total_minutes_in_day
	var hours = floor(current_minutes_float / 60)
	var minutes = floor(fmod(current_minutes_float, 60))
	return {"hours": hours, "minutes": minutes}
	
func set_current_time(hours: int, minutes: int) -> void:
	# Calculate current_time_seconds from hours and minutes
	current_time_seconds = (hours * 60 + minutes) * (day_length_seconds / total_minutes_in_day)

# New function to determine the current time period
func get_time_period() -> String:
	var hours = get_current_time().hours
	if hours >= 5 and hours < 19:
		return "Day"
	else:
		return "Night"
