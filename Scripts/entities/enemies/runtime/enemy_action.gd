class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var sound: AudioStream
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0

@export_multiline var message_template := ""

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D


func is_performable() -> bool:
	return true


func perform_action() -> void:
	pass


func get_modified_damage(base_damage: int) -> int:
	if not enemy:
		return base_damage

	var multiplier := 1.0
	if enemy.has_method("consume_damage_multiplier"):
		multiplier = enemy.consume_damage_multiplier()

	return maxi(1, int(round(base_damage * multiplier))) if base_damage > 0 else 0


func get_display_name(entity: Node) -> String:
	if "stats" in entity and entity.stats:
		return entity.stats.player_name
	return entity.name


func emit_combat_message(source: Node, target: Node, message_template: String, amount: int) -> void:
	var source_name := get_display_name(source)
	var target_name := get_display_name(target)
	
	var message := message_template.format({
		"source_name": source_name,
		"target_name": target_name,
		"amount": amount
	})
	Events.emit_signal("combat_text_emitted", message)
