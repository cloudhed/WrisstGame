extends CharacterBody2D

@export var move_speed := 32.0
var current_biomes: Array = []
# var default_move_speed := move_speed # Store the initial move speed

@export var difterrain_slowdown_percentage: float = 0.7 # 0.5 for a 50% slowdown
@export var verydifterrain_slowdown_percentage: float = 0.5 # 0.5 for a 50% slowdown

func _physics_process(_delta):
	# Debug prints to check current_biomes status:
#	print("DEBUG: current_biomes count: ", current_biomes.size())
#	for biome in current_biomes:
#		print("DEBUG: biome in list: ", biome.biome_name)
	var current_move_speed := move_speed
		
			# Check if the player is in Very Difficult Terrain biome
	var in_verydifterrain_biome := false
	for biome in current_biomes:
		if biome.biome_name == "Mountains": 
			in_verydifterrain_biome = true
			break
			
	var in_difterrain_biome := false
	for biome in current_biomes:
		if biome.biome_name == "Forest": 
			in_difterrain_biome = true
			break
	# Set the move speed based on the biome
	if in_verydifterrain_biome:
		current_move_speed = move_speed * verydifterrain_slowdown_percentage
	if in_difterrain_biome:
		current_move_speed = move_speed * difterrain_slowdown_percentage # Reduce the move speed when in the Mountain biome
#	else: current_move_speed # Reset to the default speed when not in the Mountain biome
		
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1

	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		velocity = input_vector * current_move_speed # Use the temp var for movement
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	
			
func _ready():
	# Connect signals from the child Area2D to our callbacks
	$PlayerDetectionArea.connect("area_entered", Callable(self, "_on_detection_area_entered"))
	$PlayerDetectionArea.connect("area_exited", Callable(self, "_on_detection_area_exited"))
#	_update_biome_display()

func _on_detection_area_entered(area: Node):
	# If the area is a biome and it's not already in our list, add it to our list
	print("DEBUG: Entered area: ", area.name, " | Type: ", area.get_class())
	if area is IslandBiome and not current_biomes.has(area):
		current_biomes.append(area)
		print("DEBUG: Added biome: ", area.biome_name, " | Total biomes: ", current_biomes.size())
		_update_biome_display() # Call the function to update the debug label
	else:
		print("DEBUG: Not a biome area or already in the list.")
		
func _on_detection_area_exited(area: Node):
	# If the area is a biome and it's in our list, remove it from our list
	if area is IslandBiome and current_biomes.has(area):
		current_biomes.erase(area)
		print("DEBUG: Removed biome: ", area.biome_name, " | Total biomes: ", current_biomes.size())
		_update_biome_display() # Call the function to update the debug label
	else:
		print("DEBUG: Tried to remove biome, but it wasn't in the list or not a biome: ", area.biome_name)
		

func get_current_biomes() -> IslandBiome:
	if current_biomes.is_empty():
		return null
	
	var highest_priority_biome = current_biomes[0]
	for biome in current_biomes:
		if biome.biome_priority > highest_priority_biome.biome_priority:
			highest_priority_biome = biome
	
	return highest_priority_biome
	
	
func _update_biome_display() -> void:
	# 1) Figure out highest-priority biome:
	var highest_biome = get_current_biomes() # your function that returns the top biome or null

	# 2) Convert entire array to a comma-separated list of names:
	var biome_names: Array[String] = []
	for biome in current_biomes:
		biome_names.append(biome.biome_name)

	# 3) Build the debug string:
	var debug_text = ""

	if highest_biome:
		debug_text = "Biome: " + highest_biome.biome_name
	else:
		debug_text = "Biome: !NO BIOME!"

	debug_text += "\nAll Overlapping Biomes: " + ", ".join(biome_names)

	# 4) Pass that string to the debug GUI:
	var debug_gui = get_tree().get_root().get_node("overworld_node/CanvasLayer")
	if debug_gui:
		debug_gui.set_biome(debug_text)
