# dialog_scene_selector.gd
extends Node

var _scene_cache: Dictionary = {}

const KLYFTET_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/klyftet_ext_south_day.tres"
const KLYFTET_NIGHT_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/klyftet_ext_south_night.tres"
const HOTBATHS_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/Hotbaths/hotbaths_default.tres"
const INN_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/WindbreakInn/Windbreak_Intro.tres"
const INN_POSTQUEST_NIGHT_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/WindbreakInn/Windbreak_Postquest_Night.tres"
const OLDMINE_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/Oldmine/oldmine_default.tres"
const TEMPLE_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Overworld/TempleRuins/templeruins_day.tres"
const TEMPLE_INTERIOR_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Overworld/TempleRuins/templeruins_interior_day.tres"
const SEWERS_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Klyftet/Sewers/Sewers_Day.tres"
const KEMENWOODS_INTRO_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Overworld/KemenWoods/kemenwoods_intro.tres"
const KEMENWOODS_DAY_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Overworld/KemenWoods/kemenwoods_day.tres"
const KEMENWOODS_NIGHT_SCENE_PATH := "res://Narrative/DialogScenes/Locations/Overworld/KemenWoods/kemenwoods_night.tres"


func _load_scene_cached(path: String) -> DialogSceneResource:
	if _scene_cache.has(path):
		return _scene_cache[path] as DialogSceneResource

	var resource := load(path) as DialogSceneResource
	if resource == null:
		push_error("❌ Failed to load DialogSceneResource: " + path)
		return null

	_scene_cache[path] = resource
	return resource

func get_scene(area: String) -> DialogSceneResource:
	match area:
		"klyftet":
			return _get_klyftet_scene()
		"hotbaths":
			return _get_hotbaths_scene()
		"inn":
			return _get_inn_scene()
		"oldmine":
			return _get_oldmine_scene()
		"temple":
			return _get_temple_scene()
		"temple_interior":
			return _get_temple_interior_scene()
		"market":
			return _get_market_scene()
		"sewers":
			return _get_sewers_scene()
		"kemenwoods":
			return _get_kemenwoods_scene()
		_:
			push_warning("❌ Unknown area passed to DialogSceneSelector: " + area)
			return null


func _get_klyftet_scene() -> DialogSceneResource:
	if GameState.is_night:
		return _load_scene_cached(KLYFTET_NIGHT_SCENE_PATH)
	return _load_scene_cached(KLYFTET_SCENE_PATH)


func _get_hotbaths_scene() -> DialogSceneResource:
	var first_time := not GameState.has_flag(GameState.event_flags, "hotbaths_entered_once")
	print("🏷️ First time Hotbaths?", first_time)

	if first_time:
		GameState.set_flag(GameState.event_flags, "hotbaths_entered_once")
		return _load_scene_cached(HOTBATHS_SCENE_PATH)
	else:
		return _load_scene_cached(HOTBATHS_SCENE_PATH)


func _get_inn_scene() -> DialogSceneResource:
	if GameState.is_night:
		# When a separate pre-quest night inn scene exists, add a quest flag
		# check here to branch between it and INN_POSTQUEST_NIGHT_SCENE_PATH.
		return _load_scene_cached(INN_POSTQUEST_NIGHT_SCENE_PATH)
	return _load_scene_cached(INN_SCENE_PATH)


func _get_oldmine_scene() -> DialogSceneResource:
	return _load_scene_cached(OLDMINE_SCENE_PATH)


func _get_temple_scene() -> DialogSceneResource:
	return _load_scene_cached(TEMPLE_SCENE_PATH)

func _get_temple_interior_scene() -> DialogSceneResource:
	return _load_scene_cached(TEMPLE_INTERIOR_SCENE_PATH)

func _get_sewers_scene() -> DialogSceneResource:
	if GameState.is_night:
		return _load_scene_cached(SEWERS_SCENE_PATH)
	return _load_scene_cached(SEWERS_SCENE_PATH)


func _get_kemenwoods_scene() -> DialogSceneResource:
	var first_time := not GameState.has_flag(GameState.event_flags, "kemenwoods_entered_once")

	if first_time:
		GameState.set_flag(GameState.event_flags, "kemenwoods_entered_once")
		return _load_scene_cached(KEMENWOODS_INTRO_SCENE_PATH)

	if GameState.is_night:
		return _load_scene_cached(KEMENWOODS_NIGHT_SCENE_PATH)

	return _load_scene_cached(KEMENWOODS_DAY_SCENE_PATH)


func _get_market_scene() -> DialogSceneResource:
	print("get_market_scene")
	return
