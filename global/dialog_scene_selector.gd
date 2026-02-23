# dialog_scene_selector.gd
extends Node

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
		"market":
			return _get_market_scene()
		_:
			push_warning("❌ Unknown area passed to DialogSceneSelector: " + area)
			return null


func _get_klyftet_scene() -> DialogSceneResource:
	# Example for another area, not needed now
	return preload("res://Narrative/DialogScenes/Locations/Klyftet/klyftet_ext_south_day.tres")


func _get_hotbaths_scene() -> DialogSceneResource:
	var first_time := not GameState.has_flag(GameState.event_flags, "hotbaths_entered_once")
	print("🏷️ First time Hotbaths?", first_time)

	if first_time:
		GameState.set_flag(GameState.event_flags, "hotbaths_entered_once")
		return preload("res://Narrative/DialogScenes/Locations/Klyftet/Hotbaths/hotbaths_default.tres")
	else:
		return preload("res://Narrative/DialogScenes/Locations/Klyftet/Hotbaths/hotbaths_default.tres")


func _get_inn_scene() -> DialogSceneResource:
	# Example for another area, not needed now
	return preload("res://Narrative/DialogScenes/Locations/Klyftet/WindbreakInn/Windbreak_Intro.tres")


func _get_oldmine_scene() -> DialogSceneResource:
	return preload("res://Narrative/DialogScenes/Locations/Klyftet/Oldmine/oldmine_default.tres")


func _get_market_scene() -> DialogSceneResource:
	print("get_market_scene")
	return
