class_name OverworldEncounterTrigger
extends interactable

enum ActivationMode {
	ACTIVE,
	PASSIVE_ONCE_THEN_ACTIVE,
}

const DIALOG_SCENE_PATH := "res://Narrative/DialogScene.tscn"

@export var activation_mode: ActivationMode = ActivationMode.ACTIVE

@export var prompt_active: String = "Enter"
@export var prompt_after_discovery: String = "Visit"
@export var discovery_flag: String = ""

@export var variants: Array[Resource] = []
@export var fallback_dialog_scene: DialogSceneResource
@export var fallback_scene_selector_key: String = ""

@export var debug_logging: bool = false

var _is_interactor_inside: bool = false


func interact(interactor: Node2D) -> void:
	if not _can_activate():
		return

	if _should_behave_as_active():
		_trigger_encounter(interactor)


func stop_interaction(_interactor: Node2D) -> void:
	Events.overworld_interact_prompt_hidden.emit()


func on_interactor_entered(interactor: Node2D) -> void:
	_is_interactor_inside = true

	if not _can_activate():
		Events.overworld_interact_prompt_hidden.emit()
		return

	if _should_auto_trigger_on_enter():
		_trigger_encounter(interactor)
		return

	_emit_prompt(interactor)


func on_interactor_exited(_interactor: Node2D) -> void:
	_is_interactor_inside = false
	Events.overworld_interact_prompt_hidden.emit()


func get_interaction_prompt(interactor: Node2D) -> String:
	if not _can_activate() or not _should_behave_as_active():
		return ""

	var variant = _resolve_variant(_build_context())
	if variant != null and not variant.prompt_override.is_empty():
		return variant.prompt_override

	if _is_discovered() and not prompt_after_discovery.is_empty():
		return prompt_after_discovery

	return prompt_active


func _emit_prompt(interactor: Node2D) -> void:
	var text := get_interaction_prompt(interactor)
	if text.is_empty():
		Events.overworld_interact_prompt_hidden.emit()
	else:
		Events.overworld_interact_prompt_requested.emit(text)


func _trigger_encounter(interactor: Node2D) -> void:
	var context := _build_context()
	var variant = _resolve_variant(context)

	var scene_to_open: DialogSceneResource = null
	var selector_key := ""

	if variant != null:
		scene_to_open = variant.dialog_scene
		selector_key = variant.dialog_scene_selector_key

	if scene_to_open == null:
		scene_to_open = fallback_dialog_scene
	if selector_key.is_empty():
		selector_key = fallback_scene_selector_key

	if scene_to_open != null:
		GameState.pending_dialog_scene_data = scene_to_open
		var scene := load(DIALOG_SCENE_PATH) as PackedScene
		if scene != null:
			if debug_logging:
				print("📘 OverworldEncounterTrigger opening DialogSceneResource:", scene_to_open.resource_path)
			Events.change_scene_requested.emit(scene)
		else:
			push_error("❌ OverworldEncounterTrigger failed to load dialog scene shell: " + DIALOG_SCENE_PATH)
	elif not selector_key.is_empty():
		var resolved_scene := DialogSceneSelector.get_scene(selector_key)
		if resolved_scene != null:
			GameState.pending_dialog_scene_data = resolved_scene
			var shell := load(DIALOG_SCENE_PATH) as PackedScene
			if shell != null:
				if debug_logging:
					print("📘 OverworldEncounterTrigger opening selector key:", selector_key)
				Events.change_scene_requested.emit(shell)
			else:
				push_error("❌ OverworldEncounterTrigger failed to load dialog scene shell: " + DIALOG_SCENE_PATH)
		else:
			push_warning("⚠️ OverworldEncounterTrigger selector key resolved no scene: " + selector_key)
	else:
		push_warning("⚠️ OverworldEncounterTrigger has no resolved dialog scene or selector key.")

	if not discovery_flag.is_empty() and not _is_discovered():
		GameState.set_flag(GameState.event_flags, discovery_flag)

	if _is_interactor_inside:
		_emit_prompt(interactor)


func _can_activate() -> bool:
	var context := _build_context()
	for variant in variants:
		if variant == null:
			continue
		if _variant_matches_context(variant, context):
			return true

	if fallback_dialog_scene != null or not fallback_scene_selector_key.is_empty():
		return true

	return false


func _should_auto_trigger_on_enter() -> bool:
	return activation_mode == ActivationMode.PASSIVE_ONCE_THEN_ACTIVE and not discovery_flag.is_empty() and not _is_discovered()


func _should_behave_as_active() -> bool:
	if activation_mode == ActivationMode.ACTIVE:
		return true

	# Safety fallback: if passive mode is selected but no flag is provided,
	# behave as active instead of becoming non-functional.
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


func _resolve_variant(context: Dictionary):
	for variant in variants:
		if variant == null:
			continue
		if _variant_matches_context(variant, context):
			return variant

	return null


func _variant_matches_context(variant, context: Dictionary) -> bool:
	var period := String(context.get("time_period", "Day"))
	var hours := int(context.get("hours", 12))

	if not variant.allowed_time_periods.is_empty() and not variant.allowed_time_periods.has(period):
		return false

	if not _hour_window_matches(variant, hours):
		return false

	for req_flag in variant.required_flags:
		if not _has_any_flag(req_flag, context):
			return false

	for blocked_flag in variant.blocked_flags:
		if _has_any_flag(blocked_flag, context):
			return false

	for item in variant.required_items:
		if item != null and not GameState.has_item(item):
			return false

	for item in variant.blocked_items:
		if item != null and GameState.has_item(item):
			return false

	return true


func _hour_window_matches(variant, hour: int) -> bool:
	if variant.min_hour < 0 or variant.max_hour < 0:
		return true

	if variant.min_hour <= variant.max_hour:
		return hour >= variant.min_hour and hour <= variant.max_hour

	return hour >= variant.min_hour or hour <= variant.max_hour


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
