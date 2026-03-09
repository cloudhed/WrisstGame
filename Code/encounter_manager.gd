extends Node2D

signal biome_updated(new_biome: String)

@export var combat_scene: PackedScene
@export var overworld_scene: PackedScene
@export var debug_encounter_flow: bool = true
@export var default_enemy: EnemyStats
@export var default_encounter_table: EncounterTable
@export var encounter_tables: Array[EncounterTable] = []
@onready var whiteout_anim: AnimationPlayer = $AnimationPlayer

const OVERWORLD_SCENE_PATH := "res://overworldNav.tscn"
const COMBAT_SCENE_PATH := "res://Scenes/combat.tscn"
const DEFAULT_ENEMY_PATH := "res://enemies/teqqellon/teqqellon_enemy.tres"
const DEFAULT_ENCOUNTER_TABLE_PATH := "res://Resources/Encounters/tables/default_overworld_encounter_table.tres"


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
		next_encounter_step_goal = value
		%EncounterLabel.text = str(value)

var next_encounter_step_goal: int = 100
var selected_enemy_resource: EnemyStats = null
var _last_enemy_resource: EnemyStats = null

var player_last_position: Vector2 = Vector2(460, 572)
var last_time_of_day: Dictionary = {}
var last_time_period: String = "Day"

# ⭐ NEW variable
var next_scene: PackedScene = null
var is_transitioning: bool = false
var return_from_encounter_pending: bool = false


func _ready() -> void:
	seed(randi())
	_ensure_default_encounter_content()
	_roll_next_encounter_goal(_get_active_table(), _build_encounter_context())

	# Connect to global scene change signal
	Events.change_scene_requested.connect(_on_change_scene_requested)
	Events.leave_encounter_requested.connect(_on_leave_encounter_requested) #24/11 new


func _ensure_default_encounter_content() -> void:
	if default_enemy == null:
		default_enemy = load(DEFAULT_ENEMY_PATH) as EnemyStats

	if default_encounter_table == null:
		default_encounter_table = load(DEFAULT_ENCOUNTER_TABLE_PATH) as EncounterTable

	if encounter_tables.is_empty() and default_encounter_table != null:
		encounter_tables = [default_encounter_table]

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


func get_next_encounter_step_goal() -> int:
	return max(next_encounter_step_goal, 1)


func format_distance_label(steps_since_last_event: int) -> String:
	return "Steps since last event: %d\nNext encounter at: %d" % [
		steps_since_last_event,
		get_next_encounter_step_goal()
	]


func consume_selected_enemy_resource() -> EnemyStats:
	var out := selected_enemy_resource
	selected_enemy_resource = null
	return out

func change_scene() -> void:
	var scene := _get_combat_scene()
	if scene == null:
		return

	_prepare_next_encounter_payload()
	_roll_next_encounter_goal(_get_active_table(), _build_encounter_context())
	_begin_scene_transition(scene, false, "to combat")

# ⭐ NEW: handle scene change requests with fade out
func _on_change_scene_requested(scene: PackedScene) -> void:
	if not is_instance_valid(scene):
		push_error("❌ Tried to change to an invalid scene.")
		return

	_begin_scene_transition(scene, false, "to custom scene")

func _on_leave_encounter_requested() -> void:
	var scene := _get_overworld_scene()
	if scene == null:
		push_error("❌ No overworld scene assigned for returning after encounters.")
		return

	_begin_scene_transition(scene, true, "to overworld")


func consume_return_from_encounter() -> bool:
	if return_from_encounter_pending:
		return_from_encounter_pending = false
		return true
	return false

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if not is_transitioning:
		return

	match anim_name:
		"fade_in":
			if next_scene != null:
				if debug_encounter_flow:
					print("🎬 fade_in finished -> hold white, change_scene_to_packed(next_scene)")
				var err := get_tree().change_scene_to_packed(next_scene)
				next_scene = null
				if err != OK:
					is_transitioning = false
					push_error("❌ Failed to change scene during transition. Error code: %s" % str(err))
					return

				# Hold white while new scene initializes, then fade back.
				await get_tree().process_frame
				await get_tree().process_frame

			whiteout_anim.play("fade_out")

		"fade_out":
			is_transitioning = false
			if debug_encounter_flow:
				print("✅ transition complete")


func _begin_scene_transition(target_scene: PackedScene, mark_return_from_encounter: bool, reason: String) -> void:
	if is_transitioning:
		if debug_encounter_flow:
			print("⏭️ Transition ignored (already transitioning):", reason)
		return

	_capture_overworld_player_state_if_available()

	is_transitioning = true
	next_scene = target_scene
	return_from_encounter_pending = mark_return_from_encounter
	_lock_overworld_player_movement()

	if debug_encounter_flow:
		print("🎬 begin transition -> fade_in:", reason)

	whiteout_anim.play("fade_in")


func _lock_overworld_player_movement() -> void:
	for node in get_tree().get_nodes_in_group("player_dot_instances"):
		if node is PlayerDot:
			node.can_move = false
			node.velocity = Vector2.ZERO


func _capture_overworld_player_state_if_available() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return

	var is_overworld_scene := (
		current_scene.name == "overworld_node"
		or String(current_scene.scene_file_path).ends_with("overworldNav.tscn")
	)
	if not is_overworld_scene:
		return

	var candidate: PlayerDot = null
	for node in get_tree().get_nodes_in_group("player_dot_instances"):
		if node is PlayerDot and node.is_inside_tree() and node.get_parent() != null and node.get_parent().name == "overworld_node":
			candidate = node
			break

	if candidate == null:
		candidate = current_scene.get_node_or_null("PlayerDot") as PlayerDot

	if candidate != null:
		save_player_data(candidate)
	elif debug_encounter_flow:
		print("⚠️ Could not capture overworld player state before transition (no PlayerDot found).")


func _prepare_next_encounter_payload() -> void:
	var context := _build_encounter_context()
	var table := _get_active_table()
	selected_enemy_resource = _roll_enemy_from_table(table, context)

	if selected_enemy_resource == null:
		selected_enemy_resource = table.fallback_enemy if table != null else null
	if selected_enemy_resource == null:
		selected_enemy_resource = default_enemy

	if selected_enemy_resource != null:
		_last_enemy_resource = selected_enemy_resource
		if GameState.player_statistics and selected_enemy_resource.has_method("get_species_id"):
			GameState.player_statistics.record_encounter(selected_enemy_resource.get_species_id())
		if debug_encounter_flow:
			print("🎲 Encounter enemy selected:", selected_enemy_resource.player_name)
	else:
		push_warning("⚠️ EncounterManager: no enemy selected, combat scene fallback will be used.")


func _get_active_table() -> EncounterTable:
	if encounter_tables.is_empty():
		return default_encounter_table

	for table in encounter_tables:
		if table == null:
			continue
		if table.biome_keys.is_empty() or table.biome_keys.has(combat_biome):
			return table

	return default_encounter_table


func _build_encounter_context() -> Dictionary:
	var hours: int = 12
	if last_time_of_day.has("hours"):
		hours = int(last_time_of_day["hours"])

	return {
		"biome": combat_biome,
		"hours": hours,
		"time_period": last_time_period,
		"quest_flags": GameState.quest_flags,
		"dialog_flags": GameState.dialog_flags,
		"event_flags": GameState.event_flags,
		"knowledge_flags": GameState.knowledge_flags,
		"sex_flags": GameState.sex_flags,
		"temp_flags": GameState.temp_flags,
	}


func _roll_next_encounter_goal(table: EncounterTable, context: Dictionary) -> void:
	if table == null:
		encounter_number = randi_range(50, 100)
		return

	var min_steps: int = max(table.base_steps_min, 1)
	var max_steps: int = max(table.base_steps_max, min_steps)
	var multiplier: float = table.day_steps_multiplier
	if String(context.get("time_period", "Day")) == "Night":
		multiplier = table.night_steps_multiplier

	var rolled: int = int(round(randi_range(min_steps, max_steps) * multiplier))
	encounter_number = max(rolled, 1)


func _roll_enemy_from_table(table: EncounterTable, context: Dictionary) -> EnemyStats:
	if table == null:
		return null

	var candidates: Array[EncounterEntry] = []
	for entry_res in table.entries:
		var entry := entry_res as EncounterEntry
		if entry == null:
			continue
		if entry.enemy_stats == null or entry.weight <= 0.0:
			continue
		if _entry_matches_context(entry, context):
			candidates.append(entry)

	if table.avoid_repeat_last_enemy and candidates.size() > 1 and _last_enemy_resource != null:
		var filtered: Array[EncounterEntry] = []
		for c in candidates:
			if c.enemy_stats != _last_enemy_resource:
				filtered.append(c)
		if not filtered.is_empty():
			candidates = filtered

	if candidates.is_empty():
		return null

	var total_weight := 0.0
	for c in candidates:
		total_weight += c.weight

	if total_weight <= 0.0:
		return candidates[0].enemy_stats

	var roll := randf() * total_weight
	for c in candidates:
		roll -= c.weight
		if roll <= 0.0:
			return c.enemy_stats

	return candidates.back().enemy_stats


func _entry_matches_context(entry: EncounterEntry, context: Dictionary) -> bool:
	var biome := String(context.get("biome", "Default"))
	var period := String(context.get("time_period", "Day"))
	var hours := int(context.get("hours", 12))

	if not entry.allowed_biomes.is_empty() and not entry.allowed_biomes.has(biome):
		return false

	if not entry.allowed_time_periods.is_empty() and not entry.allowed_time_periods.has(period):
		return false

	if not _hour_window_matches(entry, hours):
		return false

	for req_flag in entry.required_flags:
		if not _has_any_flag(req_flag, context):
			return false

	for blocked_flag in entry.blocked_flags:
		if _has_any_flag(blocked_flag, context):
			return false

	for item in entry.required_items:
		if item != null and not GameState.has_item(item):
			return false

	for item in entry.blocked_items:
		if item != null and GameState.has_item(item):
			return false

	return true


func _hour_window_matches(entry: EncounterEntry, hour: int) -> bool:
	if entry.min_hour < 0 or entry.max_hour < 0:
		return true

	if entry.min_hour <= entry.max_hour:
		return hour >= entry.min_hour and hour <= entry.max_hour

	# Wrap-around window, e.g. 22 -> 4
	return hour >= entry.min_hour or hour <= entry.max_hour


func _has_any_flag(flag_name: String, context: Dictionary) -> bool:
	var q: Dictionary = context.get("quest_flags", {})
	var d: Dictionary = context.get("dialog_flags", {})
	var e: Dictionary = context.get("event_flags", {})
	var k: Dictionary = context.get("knowledge_flags", {})
	var s: Dictionary = context.get("sex_flags", {})
	var t: Dictionary = context.get("temp_flags", {})

	return bool(
		q.get(flag_name, false)
		or d.get(flag_name, false)
		or e.get(flag_name, false)
		or k.get(flag_name, false)
		or s.get(flag_name, false)
		or t.get(flag_name, false)
	)
