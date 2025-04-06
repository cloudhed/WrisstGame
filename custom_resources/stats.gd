class_name Stats
extends Resource

signal stats_changed

@export var max_health := 1
@export var art: Texture
@export var playername: String = ""

var health: int : set = set_health
var block: int : set = set_block


func set_health(value : int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()


func set_block(value : int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()


func take_damage(damage: int) -> int:
	if damage <= 0:
		return 0

	var initial_health: int = health
	var blocked: int = min(damage, block)
	var net_damage: int = damage - blocked

	self.block = clampi(block - blocked, 0, 999)
	self.health = clampi(health - net_damage, 0, max_health)

	return initial_health - health # actual damage taken


func heal(amount: int) -> int:
	var pre_health := health
	self.health += amount
	return health - pre_health
	
	
func create_instance() -> Resource:
	var instance: Stats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.playername = playername
	return instance
