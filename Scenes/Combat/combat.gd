# combat.gd
class_name Combat
extends Node2D

@export var char_stats: CharacterStats
@export var music: AudioStream


@onready var combat_ui: CombatUI = $CombatUI as CombatUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: CombatPlayer = $PlayerHandler/CombatPlayer as CombatPlayer

var created_stats: CharacterStats
var combat_over: bool = false
var combat_aborted: bool = false

#enemy_loading_through_JSON
var override_enemy_resource: Resource = null

signal combat_ended


func setup_with_enemy(enemy_res: Resource) -> void:
	override_enemy_resource = enemy_res


func _ready() -> void:
	combat_ui.visible = false
	$IntentUI.visible = false

	if char_stats == null:
		print("⚠️ char_stats is null in _ready(). Using fallback GameState.player_stats.")
		char_stats = GameState.player_stats
		
	# Only create stats ONCE
	created_stats = char_stats.create_instance()
	combat_ui.char_stats = created_stats

	# UI setup
	player_handler.combat_player = player
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

	_setup_enemy()

# res://Scenes/Enemy/enemy.tscn

func _setup_enemy() -> void:
	var enemy: Enemy  # ✅ declare outside, for strict typing

	# 💣 CLEAR all existing enemies first
	#for child in enemy_handler.get_children():
		#child.queue_free()

	if override_enemy_resource:
				# 💣 CLEAR all existing enemies first
		for child in enemy_handler.get_children():
			child.queue_free()
		# 🪄 Create fresh enemy scene + set resource
		var enemy_scene: PackedScene = preload("res://Scenes/Enemy/enemy.tscn")  # your actual path
		enemy = enemy_scene.instantiate() as Enemy
		enemy_handler.add_child(enemy)
		enemy.stats = override_enemy_resource
		print("✅ Enemy spawned from dialog override:", enemy.name)
	else:
		# 🧑‍💻 Fallback for debug / editor mode
		enemy = enemy_handler.get_child(0) as Enemy
		if not enemy:
			print("❌ No enemy found in enemy_handler or override.")
			return
		print("✅ Enemy found from editor:", enemy.name)

	enemy.intent_ui = $IntentUI
	start_combat(created_stats)


func _on_player_ready(p: CombatPlayer) -> void:
	var new_stats: CharacterStats = char_stats.create_instance()
	combat_ui.char_stats = new_stats

	p.stats = new_stats
	player = p

func start_combat(stats: CharacterStats) -> void:
	print("⚔️ Combat has started!")
	combat_ui.visible = true
	$IntentUI.visible = true

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
	print("Checking enemies_child_order_changed.")

	if _all_enemies_defeated():
		print("🏆 Victory!")
		combat_over = true
#		combat_ui.visible = false
		$IntentUI.visible = false

		emit_signal("combat_ended")
		queue_free()   # ✅ also remove Combat overlay scene
		#Events.leave_encounter_requested.emit()

func _on_enemy_turn_ended() -> void:
	player_handler.turn_blocked = false
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()

func _on_player_died() -> void:
	print("☠️ Game over!")
	# You can optionally also emit leave_encounter_requested here if you want


func abort_combat() -> void:
	if combat_aborted:
		return

	print("⚠️ abort_combat() CALLED.")
	combat_aborted = true
