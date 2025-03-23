extends interactable

@export var is_captured = true :
	set(value):
		if(is_captured == value):
			return

		is_captured = value
		
		if(is_captured):
			pass
		else:
			pass

func interact(user : Node2D):
	push_warning("Not implemented")
	print_debug("Captured the flag!")
	is_captured = not is_captured

func stop_interaction(user : Node2D):
	pass
