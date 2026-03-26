extends CharacterBody2D

class_name PlayerDot

static var _active_player_dot_id: int = 0

@export var move_speed := 32.0
@export var step_size := 3
@export var debug_encounter_restore: bool = true

@onready var distance_label = get_tree().get_root().get_node("overworld_node/CanvasLayer/DistanceLabel")
@onready var coord_label = get_tree().get_root().get_node("overworld_node/CanvasLayer/CoordLabel")
@onready var debug_gui = get_tree().get_root().get_node("overworld_node/CanvasLayer")

var current_biomes: Array = []
var last_valid_biome: IslandBiome = null
var distance_in_pixel: float = 0.0:
	set(value):
		distance_in_pixel = value
		var steps = int(distance_in_pixel / step_size)
		distance_label.text = Manager.format_distance_label(steps) if Manager.has_method("format_distance_label") else "Steps since last event: %d" % steps
		var next_goal: int = Manager.get_next_encounter_step_goal() if Manager.has_method("get_next_encounter_step_goal") else Manager.encounter_number
		if steps >= next_goal:
			can_move = false
			call_deferred("_trigger_encounter")


func get_stats() -> CharacterStats:
	return stats


func _trigger_encounter():
	if debug_encounter_restore:
		print("⚔️ Trigger encounter from pos=", global_position)
	Manager.save_player_data(self)
	Manager.change_scene()

var can_move := true
var stats: CharacterStats = null
var _restore_freeze_frames: int = 0
var _is_primary_player_dot: bool = true


func _is_canonical_overworld_player_dot() -> bool:
	return name == "PlayerDot" and get_parent() != null and get_parent().name == "overworld_node"


func _disable_duplicate_player_dot(reason: String = "") -> void:
	_is_primary_player_dot = false
	set_physics_process(false)
	set_process(false)
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
	if debug_encounter_restore:
		print("⚠️ Duplicate PlayerDot disabled:", get_path(), " reason=", reason)


func _ready() -> void:
	add_to_group("player_dot_instances")

	if not _is_canonical_overworld_player_dot():
		_disable_duplicate_player_dot("non-canonical path")
		return

	for node in get_tree().get_nodes_in_group("player_dot_instances"):
		if node != self and node is PlayerDot:
			(node as PlayerDot)._disable_duplicate_player_dot("canonical PlayerDot takes ownership")

	_active_player_dot_id = get_instance_id()
	_is_primary_player_dot = true

	$PlayerDetectionArea.area_entered.connect(_on_detection_area_entered)
	$PlayerDetectionArea.area_exited.connect(_on_detection_area_exited)
	global_position = Manager.player_last_position
	velocity = Vector2.ZERO
	distance_in_pixel = 0.0

	if debug_encounter_restore:
		print("📍 PlayerDot _ready restore pos=", global_position, " path=", get_path())

	if Manager.has_method("consume_return_from_encounter") and Manager.consume_return_from_encounter():
		_restore_freeze_frames = 1
		can_move = false
		if debug_encounter_restore:
			print("🧊 Return-from-encounter movement freeze armed (1 physics frame)")
	else:
		can_move = true


func _exit_tree() -> void:
	if _is_primary_player_dot and _active_player_dot_id == get_instance_id():
		_active_player_dot_id = 0


func _physics_process(_delta: float) -> void:
	if _restore_freeze_frames > 0:
		_restore_freeze_frames -= 1
		velocity = Vector2.ZERO
		if _restore_freeze_frames == 0:
			can_move = true
			if debug_encounter_restore:
				print("✅ Return-from-encounter movement freeze released at pos=", global_position)
		return

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
	
	# coordinates
	coord_label.text = "Pos: %d, %d" % [round(position.x), round(position.y)]


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


func set_stats(new_stats: CharacterStats) -> void:
	stats = new_stats
	print("PlayerDot stats set to:", stats)
