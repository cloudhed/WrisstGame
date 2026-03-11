class_name OverworldCombatTrigger
extends interactable


enum ActivationMode {
	ACTIVE,
	PASSIVE_ONCE_THEN_ACTIVE,
}


@export_group("Activation")
@export var activation_mode: ActivationMode = ActivationMode.ACTIVE
@export var prompt_active: String = "Fight"
@export var prompt_after_discovery: String = "Fight again"
@export var discovery_flag: String = ""

@export_group("Combat Encounter")
@export var enemy_stats: EnemyStats
@export_file("*.tres") var enemy_stats_path: String = ""

@export_group("Availability Rules")
@export var allowed_time_periods: PackedStringArray = PackedStringArray()
@export_range(-1, 23, 1) var min_hour: int = -1
@export_range(-1, 23, 1) var max_hour: int = -1
@export var required_flags: PackedStringArray = PackedStringArray()
@export var blocked_flags: PackedStringArray = PackedStringArray()
@export var required_items: Array[InventoryItem] = []
@export var blocked_items: Array[InventoryItem] = []

@export_group("Debug")
@export var debug_logging: bool = false

var _is_interactor_inside: bool = false


func interact(interactor: Node2D) -> void:
	if not _can_activate():
		return

	if _should_behave_as_active():
		_trigger_combat(interactor)


func stop_interaction(_interactor: Node2D) -> void:
	Events.overworld_interact_prompt_hidden.emit()


func on_interactor_entered(interactor: Node2D) -> void:
	_is_interactor_inside = true

	if not _can_activate():
		Events.overworld_interact_prompt_hidden.emit()
		return

	if _should_auto_trigger_on_enter():
		_trigger_combat(interactor)
		return

	_emit_prompt(interactor)


func on_interactor_exited(_interactor: Node2D) -> void:
	_is_interactor_inside = false
	Events.overworld_interact_prompt_hidden.emit()


func get_interaction_prompt(interactor: Node2D) -> String:
	if not _can_activate() or not _should_behave_as_active():
		return ""

	if _is_discovered() and not prompt_after_discovery.is_empty():
		return prompt_after_discovery

	return prompt_active


func get_enemy_stats_path() -> String:
	if not enemy_stats_path.is_empty():
		return enemy_stats_path

	if enemy_stats != null:
		return enemy_stats.resource_path

	return ""


func get_enemy_stats_resource() -> EnemyStats:
	if enemy_stats != null:
		return enemy_stats

	var path := get_enemy_stats_path()
	if path.is_empty():
		return null

	return load(path) as EnemyStats


func _emit_prompt(interactor: Node2D) -> void:
	var text := get_interaction_prompt(interactor)
	if text.is_empty():
		Events.overworld_interact_prompt_hidden.emit()
	else:
		Events.overworld_interact_prompt_requested.emit(text)


func _trigger_combat(interactor: Node2D) -> void:
	var enemy_res := get_enemy_stats_resource()
	if enemy_res == null:
		push_warning("⚠️ OverworldCombatTrigger has no resolvable enemy resource.")
		return

	if not discovery_flag.is_empty() and not _is_discovered():
		GameState.set_flag(GameState.event_flags, discovery_flag)

	if debug_logging:
		print("⚔️ OverworldCombatTrigger starting combat with:", enemy_res.resource_path)

	if Manager.has_method("start_static_enemy_encounter"):
		Manager.start_static_enemy_encounter(enemy_res, interactor as PlayerDot)
	else:
		if interactor is PlayerDot:
			Manager.save_player_data(interactor as PlayerDot)
		Manager.selected_enemy_resource = enemy_res
		Manager.change_scene()

	if _is_interactor_inside:
		_emit_prompt(interactor)


func _can_activate() -> bool:
	if get_enemy_stats_path().is_empty() and enemy_stats == null:
		return false

	var context := _build_context()
	return _matches_context(context)


func _should_auto_trigger_on_enter() -> bool:
	return activation_mode == ActivationMode.PASSIVE_ONCE_THEN_ACTIVE and not discovery_flag.is_empty() and not _is_discovered()


func _should_behave_as_active() -> bool:
	if activation_mode == ActivationMode.ACTIVE:
		return true

	if activation_mode == ActivationMode.PASSIVE_ONCE_THEN_ACTIVE and discovery_flag.is_empty():
		return true

	return _is_discovered()


func _is_discovered() -> bool:
	if discovery_flag.is_empty():
		return false
	return GameState.has_flag(GameState.event_flags, discovery_flag)


func _build_context() -> Dictionary:
	var period := "Day"
	var hours := 12

	var time_node := get_tree().get_root().get_node_or_null("overworld_node/TimeOfDayControl")
	if time_node:
		if time_node.has_method("get_time_period"):
			period = String(time_node.get_time_period())
		if time_node.has_method("get_current_time"):
			var d: Dictionary = time_node.get_current_time()
			hours = int(d.get("hours", 12))

	return {
		"time_period": period,
		"hours": hours,
		"quest_flags": GameState.quest_flags,
		"dialog_flags": GameState.dialog_flags,
		"event_flags": GameState.event_flags,
		"knowledge_flags": GameState.knowledge_flags,
		"sex_flags": GameState.sex_flags,
		"temp_flags": GameState.temp_flags,
	}


func _matches_context(context: Dictionary) -> bool:
	var period := String(context.get("time_period", "Day"))
	var hours := int(context.get("hours", 12))

	if not allowed_time_periods.is_empty() and not allowed_time_periods.has(period):
		return false

	if not _hour_window_matches(hours):
		return false

	for req_flag in required_flags:
		if not _has_any_flag(req_flag, context):
			return false

	for blocked_flag in blocked_flags:
		if _has_any_flag(blocked_flag, context):
			return false

	for item in required_items:
		if item != null and not GameState.has_item(item):
			return false

	for item in blocked_items:
		if item != null and GameState.has_item(item):
			return false

	return true


func _hour_window_matches(hour: int) -> bool:
	if min_hour < 0 or max_hour < 0:
		return true

	if min_hour <= max_hour:
		return hour >= min_hour and hour <= max_hour

	return hour >= min_hour or hour <= max_hour


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