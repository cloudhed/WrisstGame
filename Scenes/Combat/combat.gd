class_name Combat
extends Node2D

@export var char_stats: CharacterStats
@export var music: AudioStream

@onready var combat_ui: CombatUI = $CombatUI as CombatUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: CombatPlayer = $PlayerHandler/CombatPlayer as CombatPlayer

#the dialog shit vvv
@onready var dialog_scene: DialogManager = $DialogUILayer/DialogScene

var created_stats: CharacterStats
var combat_over: bool = false
var combat_aborted: bool = false


func _ready() -> void:
	combat_ui.visible = false
	$IntentUI.visible = false

	# Only create stats ONCE
	created_stats = char_stats.create_instance()
	combat_ui.char_stats = created_stats

	# UI setup
	player_handler.combat_player = $PlayerHandler/CombatPlayer
	player_handler.stats_ui = %StatsUIPlayer
	enemy_handler.enemy_ui = %StatsUIEnemy

	# Signal hooks
	Events.player_ready.connect(_on_player_ready)
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_defeated.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)

	# ✅ These were missing or redundant
	if not Events.leave_encounter_requested.is_connected(_on_leave_encounter_requested):
		Events.leave_encounter_requested.connect(_on_leave_encounter_requested)

	# You can keep this extra safety net if you want
	if not Events.leave_encounter_requested.is_connected(_on_dialog_leave_requested):
		Events.leave_encounter_requested.connect(_on_dialog_leave_requested)

	_setup_enemy_and_dialog()


func _on_dialog_leave_requested() -> void:
	if combat_aborted:
		print("⚠️ Already aborted. Skipping second leave request.")
		return

	print("❌ Encounter left via dialog before combat. Setting combat_aborted = true.")
	abort_combat()

	# ✅ Only emit ONCE
	Events.leave_encounter_requested.emit()

	if dialog_scene.visible:
		dialog_scene.dialog_ended.disconnect(_on_dialog_finished)
		dialog_scene.hide()


func _setup_enemy_and_dialog() -> void:
	print("🔍 Checking enemy_handler children...")
	for i in enemy_handler.get_child_count():
		var child = enemy_handler.get_child(i)
		print("  👁️ Child [", i, "] is a:", child.get_class(), " named: ", child.name)

	var enemy := enemy_handler.get_child(0) as Enemy
	if not enemy:
		print("❌ No enemy found in enemy_handler.")
		return

	print("✅ Enemy found: ", enemy.name)

	enemy.intent_ui = $IntentUI

	# ✅ Connect leave encounter signal EARLY
	if not Events.leave_encounter_requested.is_connected(_on_dialog_leave_requested):
		Events.leave_encounter_requested.connect(_on_dialog_leave_requested)

	if enemy.stats and enemy.stats.dialog_scene_data:
		print("🗨️ Starting enemy dialog before combat...")
		dialog_scene.dialog_ended.connect(_on_dialog_finished)
		dialog_scene.visible = true
		dialog_scene.show()
		dialog_scene.start_dialog(enemy.stats.dialog_scene_data)
	else:
		print("⚔️ No dialog found. Starting combat directly.")
		start_combat(created_stats)



func _on_dialog_finished() -> void:
	print("💬 Dialog finished. Checking combat_aborted =", combat_aborted)

	dialog_scene.dialog_ended.disconnect(_on_dialog_finished)
	dialog_scene.hide()

	if combat_aborted:
		print("✅ combat_aborted is TRUE. Returning early. No combat will start.")
		return

	combat_ui.visible = true
	$IntentUI.visible = true
	start_combat(created_stats)


func _on_player_ready(p: CombatPlayer) -> void:
	var new_stats: CharacterStats = char_stats.create_instance()
	combat_ui.char_stats = new_stats

	p.stats = new_stats
	player = p # optional if you want to store the reference

	#player_handler.start_combat(new_stats)


func start_combat(stats: CharacterStats) -> void:
	print("Combat has started!")
	MusicPlayer.play(music, true)
	enemy_handler.reset_enemy_actions()
	player_handler.start_combat(stats)
	
	for enemy in enemy_handler.get_children():
		print("🧟 Enemy:", enemy.name)


func _all_enemies_defeated() -> bool:
	for child in enemy_handler.get_children():
		if child is Enemy and not child.is_defeated:
			return false
	return true


func _on_enemies_child_order_changed() -> void:
	print("Checking enemies_child_order_changed for some reason.")

	if _all_enemies_defeated():
		print("🏆 Victory!")
		
		combat_over = true  # ⛔ block further turns

		if is_instance_valid(combat_ui):
			combat_ui.visible = false
			$IntentUI.visible = false
		else:
			print("⚠️ Warning: combat_ui was already freed.")
		
		# We'll get the first defeated enemy for dialog data
		for child in enemy_handler.get_children():
			if child is Enemy and child.stats and child.stats.post_combat_dialog:
				dialog_scene.dialog_scene_data = child.stats.post_combat_dialog
				dialog_scene.dialog_ended.connect(_on_post_combat_dialog_finished)
				dialog_scene.visible = true
				dialog_scene._ready()
				return
		
		print("📦 No post-combat dialog found. Returning to overworld.")
		# _go_to_world()


func _on_enemy_turn_ended() -> void:
	player_handler.turn_blocked = false
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


func _on_post_combat_dialog_finished() -> void:
	dialog_scene.dialog_ended.disconnect(_on_post_combat_dialog_finished)
	dialog_scene.visible = false
	
	for enemy in enemy_handler.get_children():
		if enemy is Enemy and enemy.is_defeated:
			enemy.queue_free()
	Events.leave_encounter_requested.emit()
	
	
func _on_leave_encounter_requested() -> void:
	if GameState.return_to_scene != null:
		print("🔙 Returning to previous scene after combat.")
		Events.change_scene_requested.emit(GameState.return_to_scene)
		GameState.return_to_scene = null  # ✅ Reset for safety
	else:
		print("🌍 No return scene set. Going to world map.")
		Events.change_scene_requested.emit(preload("res://overworldNav.tscn"))


#func _go_to_world():
#	var world_scene: PackedScene = preload("res://overworldNav.tscn")
#	get_tree().change_scene_to_packed(world_scene)


func _on_player_died() -> void:
	print("Game over!")


func abort_combat() -> void:
	if combat_aborted:
		return

	print("⚠️ abort_combat() CALLED. Setting combat_aborted = true.")
	combat_aborted = true
