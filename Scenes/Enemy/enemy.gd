class_name Enemy
extends Area2D

#const ARROW_OFFSET := 0

@export var stats: Stats : set = set_enemy_stats

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var arrow: Sprite2D = $CanvasLayer/Arrow
@onready var stats_ui: StatsUI = $CanvasLayer/Panel/StatsUI as StatsUI


func _ready():
	print("Enemy collision layer:", collision_layer)
	print("Enemy collision mask:", collision_mask)
	print("Enemy monitoring:", monitoring)
	print("Enemy signal connected:", is_connected("area_entered", Callable(self, "_on_area_entered")))
	print("Connected:", is_connected("area_entered", Callable(self, "_on_area_entered")))

func set_enemy_stats(value: Stats) -> void:
	stats = value.create_instance()
	
	if not stats.stats_changed.is_connected(update_stats):
		stats.stats_changed.connect(update_stats)
		
	update_enemy()

func update_stats() -> void:
	stats_ui.update_stats(stats)
	
	
func update_enemy() -> void:
	if not stats is Stats:
		return
	if not is_inside_tree():
		await ready
		
	sprite_2d.texture = stats.art
#	arrow.position = Vector2.UP * (sprite_2d.get_rect().size.x / 2 + ARROW_OFFSET)
	print("Sprite rect size:", sprite_2d.get_rect().size)
#	print("Setting arrow position to:", Vector2.LEFT * (sprite_2d.get_rect().size.x / 2 + ARROW_OFFSET))
#	print("Arrow global position after update:", arrow.global_position)

	update_stats()
	
func take_damage(damage: int) -> void:
	if stats.health <= 0:
		return
	
	stats.take_damage(damage)
	
	if stats.health <= 0:
		queue_free()


func _on_area_entered(_area: Area2D) -> void:
	print("Enemy hovered!")
	arrow.show()
	print("Arrow should be showing!")


func _on_area_exited(_area: Area2D) -> void:
	print("Enemy not hovered anymore!")
	arrow.hide()
	print("Arrow should be hidden!")
