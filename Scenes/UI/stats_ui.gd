class_name StatsUI
extends VBoxContainer

@onready var block: HBoxContainer = $Block
@onready var block_label: Label = %BlockLabel
@onready var health: HBoxContainer = $Health
@onready var health_label: Label = %HealthLabel
@onready var player_name: HBoxContainer = $Name
@onready var name_label: Label = %NameLabel


func update_stats(stats: Stats) -> void:
	block_label.text = str(stats.block)
	health_label.text = "%s / %s" % [stats.health, stats.max_health]
#	health_label.text = str(stats.health) old style
	name_label.text = str(stats.player_name)
	
	block.visible = stats.block > 0
	health.visible = stats.health > 0
