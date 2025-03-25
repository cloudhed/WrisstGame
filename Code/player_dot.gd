extends CharacterBody2D

@onready var DistanceLabel: Node = get_tree().get_root().get_node("overworld_node/CanvasLayer/DistanceLabel") # Doing DISTANCE stuff
@export var move_speed := 32.0
var current_biomes: Array = [] # How we manage overlapping biomes
var last_valid_biome: IslandBiome = null # Prepping to CACHE, motherfuckers

# ---------------------------
# Biome Management Functions
# ---------------------------


		
# THE ABOVE WAS MOVED, IT WAS RECENTLY JUST BEFORE THE STEP SIZE THINGS BELOW

func add_biome(biome: IslandBiome) -> void:
	if biome not in current_biomes:
		current_biomes.append(biome)
		print("Added biome:", biome.biome_name)
	# Update cached biome if necessary
	if last_valid_biome == null or biome.biome_priority > last_valid_biome.biome_priority:
		last_valid_biome = biome

func remove_biome(biome: IslandBiome) -> void:
	if biome in current_biomes:
		current_biomes.erase(biome)
		print("Removed biome:", biome.biome_name)
	# Update cache if needed
	if last_valid_biome == biome:
		if current_biomes.size() > 0:
			last_valid_biome = get_current_biomes()
		else:
			last_valid_biome = null

func get_current_biomes() -> IslandBiome:
	if current_biomes.is_empty():
		if last_valid_biome:
			print("get_current_biomes: No current biomes, using cached biome: ", last_valid_biome.biome_name)
			return last_valid_biome
		else:
			print("get_current_biomes: No biomes ever detected! Unlucky.")
			return null

	var highest_priority_biome = current_biomes[0]
	for biome in current_biomes:
		print("get_current_biomes: Found biome: ", biome.biome_name, " with priority: ", biome.biome_priority)
		if biome.biome_priority > highest_priority_biome.biome_priority:
			highest_priority_biome = biome

	last_valid_biome = highest_priority_biome  # Cache the current biome.
	print("get_current_biomes: Selected and cached highest biome: ", highest_priority_biome.biome_name)
	return highest_priority_biome

# ---------------------------
# Rest of your code
# ---------------------------

@export var difterrain_slowdown_percentage: float = 0.7
@export var verydifterrain_slowdown_percentage: float = 0.5

func _ready():
	$PlayerDetectionArea.connect("area_entered", Callable(self, "_on_detection_area_entered"))
	$PlayerDetectionArea.connect("area_exited", Callable(self, "_on_detection_area_exited"))
	position = Manager.player_last_position
	can_move = true
	
func _on_detection_area_entered(area: Node) -> void:
	if area is IslandBiome and not current_biomes.has(area):
		add_biome(area)
		print("player_dot, on_detection_area_entered: Entered biome: ", area.biome_name)
#		current_biomes.append(area)
		_update_biome_display()

func _on_detection_area_exited(area: Node) -> void:
	if area is IslandBiome and current_biomes.has(area):
		remove_biome(area)
		print("player_dot, on_detection_area_exited: Exited biome: ", area.biome_name)
#		current_biomes.erase(area)
		_update_biome_display()

func _update_biome_display() -> void:
	var highest_biome = get_current_biomes()
	var biome_names: Array[String] = []
	for biome in current_biomes:
		biome_names.append(biome.biome_name)

	var debug_text = ""
	if highest_biome:
		debug_text = "Biome: " + highest_biome.biome_name
	else:
		debug_text = "Biome: !NO BIOME!"
	debug_text += "\nAll Overlapping Biomes: " + ", ".join(biome_names)

	var debug_gui = get_tree().get_root().get_node("overworld_node/CanvasLayer")
	if debug_gui:
		debug_gui.set_biome(debug_text)
		
var can_move := true

func _physics_process(_delta):
	if not can_move:
		velocity = Vector2.ZERO
		return # SKIPPING INPUT PROCESSING
	var current_move_speed := move_speed
	var initial_position = position
		
	var in_verydifterrain_biome := false
	for biome in current_biomes:
		if biome.biome_name == "Mountains_0": 
			in_verydifterrain_biome = true
			break
			
	var in_difterrain_biome := false
	for biome in current_biomes:
		if biome.biome_name == "Forest_0": 
			in_difterrain_biome = true
			break
		
	if in_verydifterrain_biome:
		current_move_speed = move_speed * verydifterrain_slowdown_percentage
	if in_difterrain_biome:
		current_move_speed = move_speed * difterrain_slowdown_percentage
		
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
		velocity = input_vector * current_move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	distance_in_pixel += position.distance_to(initial_position)



var step_size : int = 3
#var step_size_difterrain : int = 3 * difterrain_slowdown_percentage
#var step_size_verydifterrain : int = 3 * verydifterrain_slowdown_percentage

var distance_in_pixel : float = 0.0:
	
	set(value):
		distance_in_pixel = value
		var step = distance_in_pixel / step_size
		DistanceLabel.text = "Steps since last event: %d" % step
		if step >= Manager.encounter_number:
			print("player_dot, Manager.encounter_number: Saved player data")
			can_move = false
			print("player_dot, Manager.encounter_number: Steps reached")
			Manager.save_player_data(self)
			print("player_dot, Manager.encounter_number: movement False")
			Manager.change_scene()
			print("player_dot, Manager.encounter_number: changes scene")
