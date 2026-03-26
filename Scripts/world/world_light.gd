extends Node2D

# How bright the light glows at full night intensity.
# You can change this per-instance in the Inspector — higher = brighter.
@export var night_energy: float = 0.5

# The color of the light. Warm orange by default, matching the player light.
# You can change this per-instance in the Inspector.
@export var light_color: Color = Color(1.0, 0.75, 0.5, 1.0)

@onready var point_light: PointLight2D = $PointLight2D
@onready var time_of_day_control: Node = get_tree().get_root().get_node("overworld_node/TimeOfDayControl")

var _current_period: String = ""
var _current_tween: Tween

func _ready() -> void:
	point_light.color = light_color
	_current_period = time_of_day_control.get_time_period()
	# Set the correct energy immediately on load — no fade animation at startup
	point_light.energy = night_energy if _current_period == "Night" else 0.0

func _process(_delta: float) -> void:
	if not time_of_day_control:
		return
	var new_period: String = time_of_day_control.get_time_period()
	if new_period != _current_period:
		_current_period = new_period
		_fade_light(_current_period)

func _fade_light(period: String) -> void:
	var target_energy: float = night_energy if period == "Night" else 0.0
	# Stop any ongoing fade to avoid conflicts
	if _current_tween and _current_tween.is_running():
		_current_tween.stop()
	# Fade over 3 seconds, same as the player light
	_current_tween = create_tween()
	_current_tween.tween_property(point_light, "energy", target_energy, 3.0) \
		.set_trans(Tween.TRANS_LINEAR) \
		.set_ease(Tween.EASE_IN_OUT)
