class_name EnemyAction
extends Node

enum Type {CONDITIONAL, CHANCE_BASED}

@export var intent: Intent
@export var type: Type
@export_range(0.0, 10.0) var chance_weight := 0.0

@export_multiline var message_template := ""

@onready var accumulated_weight := 0.0

var enemy: Enemy
var target: Node2D


func is_performable() -> bool:
	return false


func perform_action() -> void:
	pass


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
