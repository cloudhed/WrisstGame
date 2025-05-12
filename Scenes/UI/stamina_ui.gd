class_name StaminaUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var stamina_label: Label = $StaminaLabel

func _ready() -> void:
	if char_stats:
		char_stats.stamina = 1
	else:
		print("⚠️ char_stats is null in _ready(). Skipping assignment.")

func _set_char_stats(value: CharacterStats) -> void:
	if value == null:
		push_warning("⚠️ _set_char_stats() received null value. Ignored.")
		return

	char_stats = value

	if not char_stats.stats_changed.is_connected(_on_stats_changed):
		char_stats.stats_changed.connect(_on_stats_changed)

	if not is_node_ready():
		await ready

	_on_stats_changed()


func _on_stats_changed() -> void:
	if char_stats == null:
		return
	stamina_label.text = "%s/%s" % [char_stats.stamina, char_stats.max_stamina]
