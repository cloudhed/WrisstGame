class_name RunButton
extends Button

func _on_pressed() -> void:
	var combat_node := get_parent()
	while combat_node != null and not combat_node.has_method("abort_combat"):
		combat_node = combat_node.get_parent()

	if combat_node:
		combat_node.abort_combat()

	Events.leave_encounter_requested.emit()
