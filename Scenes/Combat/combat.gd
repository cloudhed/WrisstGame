extends Node2D

@export var char_stats: CharacterStats

@onready var combat_ui: CombatUI = $CombatUI as CombatUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: CombatPlayer = $PlayerHandler/CombatPlayer as CombatPlayer



func _ready() -> void:
	# Normally, we would do this on a 'Run'
	# level if Roguelike, so we keep health, gold and deck
	# between combat. (Let's see how we implement this in RPG style later, probably just remove? I'll ask ChatGPT later.)
	var new_stats: CharacterStats = char_stats.create_instance()
	combat_ui.char_stats = new_stats
#	player.stats = new_stats
	
	# Connect player ready
	Events.player_ready.connect(_on_player_ready)
	
	# other signals
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)
	
		# Assign required nodes manually to handlers (THE FIX!)
	player_handler.combat_player = $PlayerHandler/CombatPlayer
	player_handler.stats_ui = $CombatUI/StatsUIManager/PlayerVBoxContainer/Panel/StatsUIPlayer
	
		# Same idea for enemy_handler if needed
	enemy_handler.enemy_ui = $CombatUI/StatsUIManager/EnemyVBoxContainer/Panel/StatsUIEnemy
	
	# Start combat
	start_combat(new_stats)


func _on_player_ready(p: CombatPlayer) -> void:
	var new_stats: CharacterStats = char_stats.create_instance()
	combat_ui.char_stats = new_stats

	p.stats = new_stats
	player = p # optional if you want to store the reference

	#player_handler.start_combat(new_stats)


func start_combat(stats: CharacterStats) -> void:
	print("Combat has started!")
	enemy_handler.reset_enemy_actions()
	player_handler.start_combat(stats)


func _on_enemies_child_order_changed() -> void:
	if enemy_handler.get_child_count() == 0:
		print("Victory!")


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()


func _on_player_died() -> void:
	print("Game over!")
