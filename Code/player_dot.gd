extends CharacterBody2D

class_name PlayerDot

@export var move_speed := 32.0
@export var step_size := 3

@onready var distance_label = get_tree().get_root().get_node("overworld_node/CanvasLayer/DistanceLabel")
@onready var debug_gui = get_tree().get_root().get_node("overworld_node/CanvasLayer")

var current_biomes: Array = []
var last_valid_biome: IslandBiome = null
var distance_in_pixel: float = 0.0:
	set(value):
		distance_in_pixel = value
		var steps = int(distance_in_pixel / step_size)
		distance_label.text = "Steps since last event: %d" % steps
		if steps >= Manager.encounter_number:
			can_move = false
			call_deferred("_trigger_encounter")
			
func _trigger_encounter():
	Manager.save_player_data(self)
	Manager.change_scene()

var can_move := true

func _ready() -> void:
	$PlayerDetectionArea.area_entered.connect(_on_detection_area_entered)
	$PlayerDetectionArea.area_exited.connect(_on_detection_area_exited)
	position = Manager.player_last_position

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		return

	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if input_vector == Vector2.ZERO:
		velocity = Vector2.ZERO
		return

	var initial_position = position
	var speed_modifier = _get_biome_speed_modifier()
	velocity = input_vector.normalized() * move_speed * speed_modifier
	move_and_slide()
	distance_in_pixel += position.distance_to(initial_position)

# Biome Management
func add_biome(biome: IslandBiome) -> void:
	if biome not in current_biomes:
		current_biomes.append(biome)
		_update_biome_display()

func remove_biome(biome: IslandBiome) -> void:
	if biome in current_biomes:
		current_biomes.erase(biome)
		if biome == last_valid_biome:
			last_valid_biome = get_highest_priority_biome()
		_update_biome_display()

func get_highest_priority_biome() -> IslandBiome:
	if current_biomes.is_empty():
		return null  # Use null to indicate "no biome" and let Manager default it
	var highest = current_biomes[0]
	for biome in current_biomes:
		if biome.biome_priority > highest.biome_priority:
			highest = biome
	last_valid_biome = highest
	return highest

func _get_biome_speed_modifier() -> float:
	var modifier = 1.0
	for biome in current_biomes:
		modifier = min(modifier, biome.get_speed_modifier() if biome.has_method("get_speed_modifier") else 1.0)
	return modifier

func _update_biome_display() -> void:
	var highest = get_highest_priority_biome()
	var biome_names = current_biomes.map(func(b): return b.biome_name)
	var text = "Biome: %s\nAll Overlapping: %s" % [
		highest.biome_name if highest else "!NO BIOME!",
		", ".join(biome_names)
	]
	if debug_gui:
		debug_gui.set_biome(text)

func _on_detection_area_entered(area: Node) -> void:
	if area is IslandBiome:
		add_biome(area)

func _on_detection_area_exited(area: Node) -> void:
	if area is IslandBiome:
		remove_biome(area)
