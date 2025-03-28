extends Camera2D

@export var target_path: NodePath
# @export var zoom

var target: Node2D

func _ready():
	if target_path:
		target = get_node(target_path)
		if not target:
			printerr("Error: Camera target node not found at path:", target_path)
	else:
		printerr("Error: Camera target path not set in the Inspector.")
	position = Manager.player_last_position
	
	# Disable smoothing to prevent the initial snap
	position_smoothing_enabled = false
	
	# Set the camera’s position to the player’s last position instantly
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		# Fallback to Manager.player_last_position if target isn’t ready yet
		global_position = Manager.player_last_position
		
# Wait one frame, then enable smoothing for subsequent movement
	#await get_tree().process_frame
	#position_smoothing_enabled = false
	# This is for the snap issue with position smoothing, I turn it off for now.

func _physics_process(_delta):
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		printerr("Error: Camera target not valid.")
