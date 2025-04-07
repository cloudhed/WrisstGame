class_name EnemyHandler
extends Node2D

var enemy_ui: StatsUI

func _ready() -> void:
	Events.enemy_action_completed.connect(_on_enemy_action_completed)


func reset_enemy_actions() -> void:
	var enemy: Enemy
	for i in get_child_count():
		enemy = get_child(i) as Enemy
		# Path to the correct StatsUI instance (adjust as needed!)
		enemy.assign_stats_ui(enemy_ui)
		enemy.current_action = null
		enemy.update_action()


func start_turn() -> void:
	print("Enemy turn starts")
	if get_child_count() == 0:
		return
	
	var first_enemy: Enemy = get_child(0) as Enemy
	print("First enemy:", first_enemy.name)
	first_enemy.do_turn()


func _on_enemy_action_completed(enemy: Enemy) -> void:
	print("Enemy action completed:", enemy.name)
	if enemy.get_index() == get_child_count() - 1:
		Events.enemy_turn_ended.emit()
		return
	
	var next_enemy: Enemy = get_child(enemy.get_index() + 1) as Enemy
	next_enemy.do_turn()
