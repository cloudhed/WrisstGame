extends Camera2D

@export var target_path: NodePath
# @export var zoom

var target: Node2D

func _ready():
	if target_path:
		target = get_node(target_path)
		if not target:
			printerr("Error: Camera target node not found at path:", target_path)
	else:
		printerr("Error: Camera target path not set in the Inspector.")
	position = Manager.player_last_position

func _physics_process(_delta):
	if is_instance_valid(target):
		global_position = target.global_position
	else:
		printerr("Error: Camera target not valid.")
