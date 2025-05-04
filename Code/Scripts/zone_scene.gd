extends Node2D
class_name ZoneScene

var dialog_manager: Node = null

func _ready() -> void:
	for hotspot in get_tree().get_nodes_in_group("hotspots"):
		if not hotspot.is_connected("hotspot_triggered", Callable(self, "_on_hotspot_triggered")):
			hotspot.connect("hotspot_triggered", Callable(self, "_on_hotspot_triggered"))

func _on_hotspot_triggered(target_id: String) -> void:
	if target_id != "" and dialog_manager:
		if dialog_manager.flow_manager:
			dialog_manager.flow_manager.jump_to_id(target_id)
		else:
			push_error("❌ flow_manager is null on dialog_manager")
