extends Node

@onready var world_environment: WorldEnvironment = get_node("WorldEnvironment") # Adjust this path if your WorldEnvironment is in a different location
@onready var time_of_day_control: Node = get_tree().get_root().get_node("overworld_node/TimeOfDayControl")  # Full path to TimeOfDayControl
@onready var player_light: Light2D = get_node("../PlayerDot/PlayerLight")  # Adjust path as needed

var current_period: String = ""
var current_tween: Tween  # Holds the active Tween instance

func _ready():
	# Ensure Tween node exists; create it if not
#	if not has_node("Tween"):
#		var new_tween = Tween.new()
#		new_tween.name = "Tween"
#		add_child(new_tween)
#		tween = new_tween
		
	# Set initial period and light energy based on starting time
	current_period = time_of_day_control.get_time_period()
	if current_period == "Day":
		player_light.energy = 0.0
	else:
		player_light.energy = 0.32

func _process(_delta):
	if world_environment and time_of_day_control and time_of_day_control.has_method("get_current_time"):
		var current_time = time_of_day_control.get_current_time()
		var hours = current_time.hours
		var minutes = current_time.minutes
#		print("DEBUG: Time is:", hours)

		var total_minutes_in_day = hours * 60 + minutes
		var normalized_time = total_minutes_in_day / 1440.0
		var progress = (cos(normalized_time * 2 * PI) + 1) / 2
		
		# Post Process Glow and bloom
		world_environment.environment.glow_enabled = true
		world_environment.environment.glow_intensity = progress * 4.0
		
		# Check for period change using get_time_period()
		var new_period = time_of_day_control.get_time_period()
		if new_period != current_period:
			current_period = new_period
			fade_player_light(current_period)

# Function to fade the PlayerLight’s energy based on the period
func fade_player_light(period: String):
	var target_energy: float
	if period == "Night":
		target_energy = 0.32
	else:
		target_energy = 0.0
	
	# Stop any ongoing tween to avoid conflicts
	if current_tween and current_tween.is_running():
		current_tween.stop()
	
	# Fade energy over 3 seconds
	current_tween = create_tween()
	current_tween.tween_property(player_light, "energy", target_energy, 3.0)\
		.set_trans(Tween.TRANS_LINEAR)\
		.set_ease(Tween.EASE_IN_OUT)
