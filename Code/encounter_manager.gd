extends Node2D

signal biome_updated(new_biome: String)

@export var combat_scene: PackedScene
@export var overworld_scene: PackedScene
@export var debug_encounter_flow: bool = true
@onready var whiteout_anim: AnimationPlayer = $AnimationPlayer

const OVERWORLD_SCENE_PATH := "res://overworldNav.tscn"
const COMBAT_SCENE_PATH := "res://Scenes/combat.tscn"


func _get_combat_scene() -> PackedScene:
	if combat_scene == null:
		combat_scene = load(COMBAT_SCENE_PATH) as PackedScene
		if combat_scene == null:
			push_error("❌ encounter_manager: failed to load combat scene: " + COMBAT_SCENE_PATH)
	return combat_scene


func _get_overworld_scene() -> PackedScene:
	if overworld_scene == null:
		overworld_scene = load(OVERWORLD_SCENE_PATH) as PackedScene
		if overworld_scene == null:
			push_error("❌ encounter_manager: failed to load overworld scene: " + OVERWORLD_SCENE_PATH)
	return overworld_scene

var combat_biome: String = "Default"
var encounter_number: int = 100:
	set(value):
		encounter_number = value
		%EncounterLabel.text = str(value)

var player_last_position: Vector2 = Vector2(460, 572)
var last_time_of_day: Dictionary = {}
var last_time_period: String = "Day"

# ⭐ NEW variable
var next_scene: PackedScene = null
var is_transitioning: bool = false
var return_from_encounter_pending: bool = false

func _ready() -> void:
	seed(randi())
	encounter_number = randi_range(50, 100)

	# Connect to global scene change signal
	Events.change_scene_requested.connect(_on_change_scene_requested)
	Events.leave_encounter_requested.connect(_on_leave_encounter_requested) #24/11 new

func save_player_data(player: PlayerDot) -> void:
	var biome_obj = player.get_highest_priority_biome()
	combat_biome = biome_obj.biome_name if biome_obj else "Default"
	GameState.player_stats = player.get_stats()
	player_last_position = player.global_position

	if debug_encounter_flow:
		print("📌 Encounter save_player_data pos=", player_last_position)

	var time_node = get_tree().get_root().get_node_or_null("overworld_node/TimeOfDayControl")
	if time_node:
		last_time_of_day = time_node.get_current_time() if time_node.has_method("get_current_time") else {}
		last_time_period = time_node.get_time_period() if time_node.has_method("get_time_period") else "Day"

	emit_signal("biome_updated", combat_biome)

func change_scene() -> void:
	if is_transitioning:
		if debug_encounter_flow:
			print("⏭️ change_scene ignored (already transitioning).")
		return

	is_transitioning = true
	return_from_encounter_pending = false
	next_scene = null

	if debug_encounter_flow:
		print("🎬 change_scene -> fade_in (to combat)")

	whiteout_anim.play("fade_in")
	encounter_number = randi_range(200, 500)

# ⭐ NEW: handle scene change requests with fade out
func _on_change_scene_requested(scene: PackedScene) -> void:
	if is_transitioning:
		if debug_encounter_flow:
			print("⏭️ change_scene_requested ignored (already transitioning).")
		return

	if is_instance_valid(scene):
		is_transitioning = true
		next_scene = scene
		if debug_encounter_flow:
			print("🎬 change_scene_requested -> fade_out (custom scene)")
		whiteout_anim.play("fade_out")
	else:
		push_error("❌ Tried to change to an invalid scene.")

func _on_leave_encounter_requested() -> void:
	if is_transitioning:
		if debug_encounter_flow:
			print("⏭️ leave_encounter ignored (already transitioning).")
		return

	var scene := _get_overworld_scene()
	if scene:
		is_transitioning = true
		return_from_encounter_pending = true
		next_scene = scene
		if debug_encounter_flow:
			print("🏃 leave_encounter -> fade_out (to overworld)")
		whiteout_anim.play("fade_out")
	else:
		push_error("❌ No overworld scene assigned for returning after encounters.")


func consume_return_from_encounter() -> bool:
	if return_from_encounter_pending:
		return_from_encounter_pending = false
		return true
	return false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"fade_in":
			var scene := _get_combat_scene()
			if scene:
				if debug_encounter_flow:
					print("🎬 fade_in finished -> change_scene_to_packed(combat)")
				get_tree().call_deferred("change_scene_to_packed", scene)
			whiteout_anim.play("fade_out")

		# ⭐ NEW: change to any requested scene after fade_out
		"fade_out":
			if next_scene != null:
				if debug_encounter_flow:
					print("🎬 fade_out finished -> change_scene_to_packed(next_scene)")
				get_tree().change_scene_to_packed(next_scene)
				next_scene = null

			is_transitioning = false
			if debug_encounter_flow:
				print("✅ transition complete")
