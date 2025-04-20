class_name EnemyHandler
extends Node2D

var enemy_ui: StatsUI

func _ready() -> void:
	print("📦 EnemyHandler ready")
	Events.enemy_action_completed.connect(_on_enemy_action_completed)

func reset_enemy_actions() -> void:
	print("♻️ Resetting enemy actions...")
	for i in get_child_count():
		var enemy: Enemy = get_child(i) as Enemy
		print("🔄 Resetting:", enemy.name)
		enemy.assign_stats_ui(enemy_ui)
		enemy.current_action = null
		enemy.update_action()

func start_turn() -> void:
	var combat = get_tree().get_current_scene() as Combat
	if combat and combat.combat_over:
		print("⛔ Combat is over — skipping enemy start_turn.")
		Events.enemy_turn_ended.emit()
		return

	print("⚔️ Enemy turn starts")

	var first_enemy: Enemy = null

	for child in get_children():
		if child is Enemy and not child.is_defeated:
			first_enemy = child
			break

	if first_enemy == null:
		print("❌ No active enemies found! Ending turn.")
		Events.enemy_turn_ended.emit()
		return

	print("🎯 First enemy:", first_enemy.name)
	first_enemy.do_turn()

func _on_enemy_action_completed(enemy: Enemy) -> void:
	print("✅ Enemy action completed:", enemy.name)
	
	if enemy.get_index() == get_child_count() - 1:
		print("📴 Last enemy acted, ending turn.")
		Events.enemy_turn_ended.emit()
		return
	
	var next_enemy: Enemy = get_child(enemy.get_index() + 1) as Enemy
	print("➡️ Next enemy turn:", next_enemy.name)
	next_enemy.do_turn()
