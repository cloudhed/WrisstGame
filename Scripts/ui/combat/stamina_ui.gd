class_name StaminaUI
extends Panel

@export var char_stats: CharacterStats : set = _set_char_stats
@export var stamina_unit_size := 10.0
@export var fill_tween_duration := 0.12

@onready var stamina_label: Label = $StaminaLabel
@onready var stamina_progress_bar: ProgressBar = %StaminaProgressBar

var _fill_tween: Tween

func _ready() -> void:
	if char_stats == null:
		print("⚠️ char_stats is null in _ready(). Skipping stamina UI update.")
		return

	_on_stats_changed()

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

	var scaled_max_stamina := maxf(char_stats.max_stamina * stamina_unit_size, 0.0)
	var scaled_stamina := clampf(char_stats.stamina * stamina_unit_size, 0.0, scaled_max_stamina)

	stamina_label.text = "%s/%s" % [char_stats.stamina, char_stats.max_stamina]
	stamina_progress_bar.max_value = scaled_max_stamina
	_update_progress_bar_value(scaled_stamina)


func _update_progress_bar_value(target_value: float) -> void:
	if stamina_progress_bar == null:
		return

	if _fill_tween and _fill_tween.is_valid():
		_fill_tween.kill()

	if not is_node_ready() or fill_tween_duration <= 0.0:
		stamina_progress_bar.value = target_value
		return

	_fill_tween = create_tween()
	_fill_tween.set_ease(Tween.EASE_OUT)
	_fill_tween.set_trans(Tween.TRANS_EXPO)
	_fill_tween.tween_property(stamina_progress_bar, "value", target_value, fill_tween_duration)
