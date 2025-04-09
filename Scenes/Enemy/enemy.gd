class_name Enemy
extends Area2D

#const ARROW_OFFSET := 0
const WHITE_SPRITE_MATERIAL := preload("res://Shaders/white_sprite_material.tres")

@export var stats: EnemyStats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $CanvasLayer/Arrow
#@onready var stats_ui: StatsUI = $CanvasLayer/Panel/StatsUI as StatsUI
@onready var intent_ui: IntentUI = $CanvasLayer/IntentUI as IntentUI

# Onready VFX
@onready var lifesteal_vfx: GPUParticles2D = $ParticleVFX/LifestealVFX
@onready var mega_block_vfx: GPUParticles2D = $ParticleVFX/MegaBlockVFX

var enemy_action_picker: EnemyActionPicker
var current_action: EnemyAction : set = set_current_action


func get_stats():
	return stats


func set_current_action(value: EnemyAction) -> void:
	current_action = value
	if current_action:
		intent_ui.update_intent(current_action.intent)


func set_enemy_stats(value: EnemyStats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		stats.stats_changed.connect(update_action)
		
	update_enemy()


func setup_ai() -> void:
	if enemy_action_picker:
		enemy_action_picker.queue_free()
	
	var new_action_picker: EnemyActionPicker = stats.ai.instantiate()
	add_child(new_action_picker)
	enemy_action_picker = new_action_picker
	enemy_action_picker.enemy = self
	update_action()


var stats_ui: StatsUI = null

func assign_stats_ui(ui: StatsUI) -> void:
	stats_ui = ui
	stats_ui.update_stats(stats)


func update_stats() -> void:
	if stats_ui:
		stats_ui.update_stats(stats)


func update_action() -> void:
	if not enemy_action_picker:
		return
	
	if not current_action:
		current_action = enemy_action_picker.get_action()
		return
	
	var new_conditional_action := enemy_action_picker.get_first_conditional_action()
	if new_conditional_action and current_action != new_conditional_action:
		current_action = new_conditional_action


func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
		
	sprite_2d.texture = stats.art
	setup_ai()
	
	if stats_ui:
		update_stats()
		
	update_action()
#	arrow.position = Vector2.UP * (sprite_2d.get_rect().size.x / 2 + ARROW_OFFSET)
#	print("Sprite rect size:", sprite_2d.get_rect().size)
#	print("Setting arrow position to:", Vector2.LEFT * (sprite_2d.get_rect().size.x / 2 + ARROW_OFFSET))
#	print("Arrow global position after update:", arrow.global_position)


func do_turn() -> void:
	stats.block = 0
	
	if not current_action:
		print("No current action!")
		return
	
	print("Enemy performing action:", current_action)
	current_action.perform_action()


func take_damage(damage: int) -> void:
	if stats.health <= 0:
		return
	
	sprite_2d.material = WHITE_SPRITE_MATERIAL
	
	var tween := create_tween()
	tween.tween_callback(Shaker.shake.bind(self, 16, 0.15))
	tween.tween_callback(stats.take_damage.bind(damage))
	tween.tween_interval(0.17)
	
	tween.finished.connect(
		func():
			sprite_2d.material = null
			
			if stats.health <= 0:
				queue_free()
	)


func _on_area_entered(_area: Area2D) -> void:
	print("Enemy hovered!")
	#arrow.show()
	#print("Arrow should be showing!")


func _on_area_exited(_area: Area2D) -> void:
	print("Enemy not hovered anymore!")
	#arrow.hide()
	#print("Arrow should be hidden!")
