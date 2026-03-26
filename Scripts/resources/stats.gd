class_name Stats
extends Resource

signal stats_changed

@export var max_health := 1
@export var art: Texture
@export var player_name: String = ""

var health: int : set = set_health
var block: int : set = set_block
var entity: Node = null


func resolve_damage(damage: int) -> Dictionary:
	var attempted: int = maxi(damage, 0)
	var blocked: int = mini(block, attempted)
	var dealt: int = maxi(attempted - blocked, 0)
	return {
		"attempted": attempted,
		"blocked": blocked,
		"dealt": dealt,
	}

func set_health(value : int) -> void:
	health = clampi(value, 0, max_health)
	stats_changed.emit()


func set_block(value : int) -> void:
	block = clampi(value, 0, 999)
	stats_changed.emit()


func take_damage(damage: int) -> Dictionary:
	var result := resolve_damage(damage)
	if int(result["attempted"]) <= 0:
		return result

	self.block = clampi(block - int(result["attempted"]), 0, block)
	self.health -= int(result["dealt"])
	return result


func take_true_damage(damage: int) -> void:
	if damage <= 0:
		return

	self.health -= damage


func heal(amount: int) -> void:
	self.health += amount
	
	
func create_instance() -> Resource:
	var instance: Stats = self.duplicate()
	instance.health = max_health
	instance.block = 0
	instance.player_name = player_name
	return instance
