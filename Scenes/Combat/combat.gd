extends Node2D

@export var char_stats: CharacterStats

@onready var combat_ui: CombatUI = $CombatUI as CombatUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: CombatPlayer = $CombatUI/HBoxContainer/PlayerVBoxContainer/CombatPlayer as CombatPlayer


func _ready() -> void:
	# Normally, we would do this on a 'Run'
	# level if Roguelike, so we keep health, gold and deck
	# between combat. (Let's see how we implement this in RPG style later, probably just remove? I'll ask ChatGPT later.)
	var new_stats: CharacterStats = char_stats.create_instance()
	combat_ui.char_stats = new_stats
	player.stats = new_stats
	
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	
	start_combat(new_stats)


func start_combat(stats: CharacterStats) -> void:
	print("Combat has started!")
	enemy_handler.reset_enemy_actions()
	player_handler.start_combat(stats)


func _on_enemy_turn_ended() -> void:
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()
