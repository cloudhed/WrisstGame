class_name CombatPlayer
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://Assets/Shaders/white_sprite_material.tres")

@export var stats: CharacterStats : set = set_character_stats
@export var auto_end_turn_on_zero_stamina: bool = true

@onready var sprite_2d: Sprite2D = $Sprite2D # For player sprite white flash
#@onready var stats_ui: StatsUI = $CanvasLayer/Panel/StatsUI as StatsUI
@onready var end_turn_timer: Timer = $EndTurnTimer
@onready var game_state = GameState
@onready var display_name: String = GameState.player_name
var has_scheduled_end_turn: bool = false
var _last_logged_stamina: int = -999999
var _last_logged_end_turn_flag: bool = false

var stats_ui: StatsUI = null


func _ready() -> void:
	Events.player_ready.emit(self)
	
	#getplayername
	if display_name.is_empty():
		display_name = GameState.player_name
	
	if not end_turn_timer.timeout.is_connected(_on_end_turn_timer_timeout):
		end_turn_timer.timeout.connect(_on_end_turn_timer_timeout)


func assign_stats_ui(ui: StatsUI) -> void:
	stats_ui = ui
	_refresh_stats_ui()



func set_character_stats(value: CharacterStats) -> void:
	if value == null:
		push_warning("⚠️ set_character_stats() received null value. Ignored.")
		return

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
	_refresh_stats_ui()
	_evaluate_end_turn_state()


func _refresh_stats_ui() -> void:
	if stats_ui:
		stats_ui.update_stats(stats)


func _evaluate_end_turn_state() -> void:
	if stats == null:
		return

	var stamina_changed := stats.stamina != _last_logged_stamina
	var flag_changed := has_scheduled_end_turn != _last_logged_end_turn_flag
	if stamina_changed or flag_changed:
		print("[DEBUG] Player stats sync — Stamina:", stats.stamina, " | has_scheduled_end_turn:", has_scheduled_end_turn)
		_last_logged_stamina = stats.stamina
		_last_logged_end_turn_flag = has_scheduled_end_turn

	# Start the end-turn countdown ONLY ONCE when stamina hits 0
	if auto_end_turn_on_zero_stamina and stats.stamina <= 0 and not has_scheduled_end_turn:
		print("[DEBUG] Stamina is 0 — scheduling end turn.")
		has_scheduled_end_turn = true
		end_turn_timer.start()
		_last_logged_end_turn_flag = has_scheduled_end_turn
	elif stats.stamina > 0 and has_scheduled_end_turn:
		print("[DEBUG] Stamina restored — canceling timer and reset flag.")
		has_scheduled_end_turn = false
		end_turn_timer.stop()
		_last_logged_end_turn_flag = has_scheduled_end_turn


func spend_stamina(amount: int) -> void:
	if stats.stamina <= 0:
		return
	
	var new_value: int = max(0, stats.stamina - amount)
	stats.stamina = new_value


func get_stats() -> CharacterStats:
	return stats


func get_display_name() -> String:
	if stats and not stats.player_name.is_empty():
		return stats.player_name
	if not display_name.is_empty():
		return display_name
	return name


func get_damage_popup_position() -> Vector2:
	if has_node("DamagePopupAnchor"):
		return get_node("DamagePopupAnchor").global_position
	return global_position  # fallback


func take_damage(damage: int) -> Dictionary:
	if stats.health <= 0:
		return stats.resolve_damage(0)

	var damage_result := stats.resolve_damage(damage)
		
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
	return damage_result
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
