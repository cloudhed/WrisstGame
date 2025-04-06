class_name CombatPlayer
extends Node2D

const WHITE_SPRITE_MATERIAL := preload("res://Shaders/white_sprite_material.tres")

@export var stats: CharacterStats : set = set_character_stats

#@onready var sprite_2d: Sprite2D = $Sprite2D # For player sprite white flash
@onready var stats_ui: StatsUI = $CanvasLayer/Panel/StatsUI as StatsUI


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
	stats_ui.update_stats(stats)


func take_damage(damage: int) -> void:
	if stats.health <= 0:
		return
		
#	sprite_2d.material = WHITE_SPRITE_MATERIAL # For player sprite white flash
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_callback(stats.take_damage.bind(damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
#			sprite_2d.material = null # For player sprite white flash
			
			if stats.health <= 0:
				Events.player_died.emit()
				queue_free()
	)
#	stats.take_damage(damage)
	
#	if stats.health <= 0:
#		Events.player_died.emit()
#		queue_free()
