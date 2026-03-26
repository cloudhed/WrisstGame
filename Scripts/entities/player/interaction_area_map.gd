extends Area2D

@export var interactor : Node2D
@export var interaction_action : StringName = "interact"

var selected_interactable : interactable
var nearby_interactables : Array[interactable] = []

func _ready():
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func _process(_delta):
	pass

func _input(event: InputEvent) -> void:
	if(event.is_action_pressed(interaction_action)):
		if(selected_interactable != null):
			selected_interactable.interact(interactor)

func _on_area_entered(area : Area2D):
	if(area is interactable):
		nearby_interactables.push_back(area)
		area.on_interactor_entered(interactor)
		
		if(selected_interactable == null):
			selected_interactable = nearby_interactables[0]
		_update_prompt()
			
func _on_area_exited(area : Area2D):
	if(area is interactable):
		nearby_interactables.erase(area)
		area.on_interactor_exited(interactor)
		
		if selected_interactable == area:
			selected_interactable.stop_interaction(interactor)
			selected_interactable = null
		
		if(nearby_interactables.size() > 0):
			selected_interactable = nearby_interactables[0]

		_update_prompt()


func _update_prompt() -> void:
	if selected_interactable == null:
		Events.overworld_interact_prompt_hidden.emit()
		return

	var prompt := selected_interactable.get_interaction_prompt(interactor)
	if prompt.is_empty():
		Events.overworld_interact_prompt_hidden.emit()
	else:
		Events.overworld_interact_prompt_requested.emit(prompt)
