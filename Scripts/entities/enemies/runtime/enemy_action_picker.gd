class_name EnemyActionPicker
extends Node

@export var enemy: Enemy: set = _set_enemy
@export var target: Node2D: set = _set_target

@onready var total_weight := 0.0


func _ready() -> void:
	target = get_tree().get_first_node_in_group("player")
	setup_chances()


func get_action() -> EnemyAction:
	var action := get_first_conditional_action()
	if action:
		return action
	
	return get_chance_based_action()


func get_first_conditional_action() -> EnemyAction:
	var action: EnemyAction
	
	for child in get_children():
		action = child as EnemyAction
		if not action or action.type != EnemyAction.Type.CONDITIONAL:
			continue
		
		if action.is_performable():
			return action
	
	return null


func get_chance_based_action() -> EnemyAction:
	var available_actions: Array[EnemyAction] = []
	var available_total_weight := 0.0

	for child in get_children():
		var action := child as EnemyAction
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		if not action.is_performable():
			continue

		available_actions.append(action)
		available_total_weight += action.chance_weight

	if available_actions.is_empty():
		return null

	var roll := randf_range(0.0, available_total_weight)
	var running_weight := 0.0
	for action in available_actions:
		running_weight += action.chance_weight
		if running_weight >= roll:
			return action
	
	return null


func setup_chances() -> void:
	var action: EnemyAction
	
	for child in get_children():
		action = child as EnemyAction
		if not action or action.type != EnemyAction.Type.CHANCE_BASED:
			continue
		
		total_weight += action.chance_weight
		action.accumulated_weight = total_weight


func _set_enemy(value: Enemy) -> void:
	enemy = value
	
	for action in get_children():
		action.enemy = enemy


func _set_target(value: Node2D) -> void:
	target = value
	
	for action in get_children():
		action.target = target
