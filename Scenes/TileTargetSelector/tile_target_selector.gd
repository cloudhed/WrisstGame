extends Node2D


@onready var area_2d: Area2D = $Area2D

var current_tile: TileUI
var targeting := false


func _describe_target(area: Area2D) -> String:
	if area == null:
		return "<null>"
	if area.has_method("get_display_name"):
		var display_name = area.get_display_name()
		if display_name != null and not String(display_name).is_empty():
			return String(display_name)
	return area.name


func _ready() -> void:
	Events.tile_aim_started.connect(_on_tile_aim_started)
	Events.tile_aim_ended.connect(_on_tile_aim_ended)


func _process(_delta: float) -> void:
	if not targeting:
		return
	area_2d.position = get_local_mouse_position()
	
#	var overlaps = area_2d.get_overlapping_areas()
#	print("Overlapping areas:", overlaps.size())

func _on_tile_aim_started(tile: TileUI) -> void:
	if not tile.tile.is_single_targeted():
		return
		
	targeting = true
	print("TargetSelector Active!")
	print("Area2D Layer:", area_2d.collision_layer)
	print("Area2D Mask:", area_2d.collision_mask)
	area_2d.monitoring = true
	area_2d.monitorable = true
	print("monitoring:", area_2d.monitoring, " | monitorable:", area_2d.monitorable)
	current_tile = tile
	
	
func _on_tile_aim_ended(_tile: TileUI) -> void:
	targeting = false
	area_2d.position = Vector2.ZERO
	area_2d.monitoring = false
	area_2d.monitorable = false
	current_tile = null
	
	
func _on_area_2d_area_entered(area: Area2D) -> void:
	print("Selector hit:", _describe_target(area))
	if not current_tile or not targeting:
		return
		
	if not current_tile.targets.has(area):
		current_tile.targets.append(area)


func _on_area_2d_area_exited(area: Area2D) -> void:
	if not current_tile or not targeting:
		return
		
	current_tile.targets.erase(area)
