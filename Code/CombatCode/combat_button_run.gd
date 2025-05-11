class_name RunButton
extends Button

@export var world : PackedScene

func _on_pressed() -> void:
	Events.leave_encounter_requested.emit()
#	get_tree().change_scene_to_packed(world)
