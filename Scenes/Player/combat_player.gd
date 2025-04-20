class_name CombatPlayer
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://Shaders/white_sprite_material.tres")

@export var stats: CharacterStats : set = set_character_stats

@onready var sprite_2d: Sprite2D = $Sprite2D # For player sprite white flash
#@onready var stats_ui: StatsUI = $CanvasLayer/Panel/StatsUI as StatsUI
@onready var end_turn_timer: Timer = $EndTurnTimer
var has_scheduled_end_turn: bool = false

var stats_ui: StatsUI = null


func _ready() -> void:
	Events.player_ready.emit(self)
	if not end_turn_timer.timeout.is_connected(_on_end_turn_timer_timeout):
		end_turn_timer.timeout.connect(_on_end_turn_timer_timeout)


func assign_stats_ui(ui: StatsUI) -> void:
	stats_ui = ui
	stats_ui.update_stats(stats)


func set_character_stats(value: CharacterStats) -> void:
	stats = value
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		
	update_player()


func update_player() -> void:
	if not stats is CharacterStats:
		return
	if not is_inside_tree():
		await ready
	
	#player_name.string = stats.name
	update_stats()


func update_stats() -> void:
	if stats_ui:
		stats_ui.update_stats(stats)

	print("[DEBUG] update_stats called — Stamina:", stats.stamina, " | has_scheduled_end_turn:", has_scheduled_end_turn)

	# Start the end-turn countdown ONLY ONCE when stamina hits 0
	if stats.stamina <= 0 and not has_scheduled_end_turn:
		print("[DEBUG] Stamina is 0 — scheduling end turn.")
		has_scheduled_end_turn = true
		end_turn_timer.start()
	elif stats.stamina > 0 and has_scheduled_end_turn:
		print("[DEBUG] Stamina restored — canceling timer and reset flag.")
		has_scheduled_end_turn = false
		end_turn_timer.stop()


func spend_stamina(amount: int) -> void:
	if stats.stamina <= 0:
		return
	
	var new_value: int = max(0, stats.stamina - amount)
	stats.stamina = new_value
	update_stats()


func take_damage(damage: int) -> void:
	if stats.health <= 0:
		return
		
	sprite_2d.material = WHITE_SPRITE_MATERIAL # For player sprite white flash
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_callback(stats.take_damage.bind(damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null # For player sprite white flash
			
			if stats.health <= 0:
				Events.player_died.emit()
				queue_free()
	)
#	stats.take_damage(damage)
	
#	if stats.health <= 0:
#		Events.player_died.emit()
#		queue_free()


func _on_end_turn_timer_timeout() -> void:
	print("[DEBUG] Timer timeout reached. Checking stamina...")

	if stats.stamina <= 0:
		print("[DEBUG] Confirmed 0 stamina — emitting player_turn_ended.")
		
		# Prevent another turn from starting before enemy goes
		var parent := get_parent()
		if parent is PlayerHandler:
			parent.turn_blocked = true

		Events.player_turn_ended.emit()
	else:
		print("[DEBUG] Stamina recovered before timer finished — no turn end.")

	has_scheduled_end_turn = false
