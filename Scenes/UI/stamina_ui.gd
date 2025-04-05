class_name StaminaUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var stamina_label: Label = $StaminaLabel

func _ready() -> void:
	await get_tree().create_timer(2).timeout
	char_stats.stamina = 1

func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	
	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)
		
	if not is_node_ready():
		await ready
		
	_on_stats_changed()


func _on_stats_changed() -> void:
	stamina_label.text = "%s/%s" % [char_stats.stamina, char_stats.max_stamina]
