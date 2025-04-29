extends Node2D
class_name ZoneScene

var dialog_manager: Node = null

func _ready() -> void:
	for hotspot in get_tree().get_nodes_in_group("hotspots"):
		hotspot.connect("hotspot_triggered", Callable(self, "_on_hotspot_triggered"))

func _on_hotspot_triggered(target_id: String) -> void:
	if target_id != "" and dialog_manager:
		dialog_manager.jump_to_dialog(target_id)
