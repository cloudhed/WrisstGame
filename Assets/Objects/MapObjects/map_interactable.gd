class_name interactable
extends Area2D

func interact(interactor : Node2D):
	push_warning("Not implemented")

func stop_interaction(interactor : Node2D):
		push_warning("Not implemented")


func get_interaction_prompt(_interactor: Node2D) -> String:
	return ""


func on_interactor_entered(_interactor: Node2D) -> void:
	pass


func on_interactor_exited(_interactor: Node2D) -> void:
	pass
