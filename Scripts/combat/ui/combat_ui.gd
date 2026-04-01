class_name CombatUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats
@export var end_turn_pulse_color: Color = Color(2.2, 1.9, 1.4, 1.0)
@export var end_turn_pulse_scale: Vector2 = Vector2(1.02, 1.02)
@export var end_turn_pulse_duration := 0.7
@export var end_turn_glow_min_alpha := 0.28
@export var end_turn_glow_max_alpha := 1.0
@export var end_turn_glow_pulse_scale: Vector2 = Vector2(1.18, 1.18)

@onready var hand: Hand = $Hand as Hand
@onready var stamina_ui: StaminaUI = $StaminaUI as StaminaUI
@onready var end_turn_button: Button = %EndTurnButton
@onready var end_turn_glow: TextureRect = $EndTurnButton/EndTurnGlow
@onready var run_button: Button = $StatsUIManager/PlayerVBoxContainer/PlayerMenuUI/CombatButtonRUN
#@onready var combat_text = $StatsUIManager/CombatTextUI/MarginContainer/CombatText as RichTextLabel

var _is_player_turn := false
var _end_turn_pulse_tween: Tween
var _end_turn_base_modulate: Color = Color.WHITE
var _end_turn_base_scale: Vector2 = Vector2.ONE
var _end_turn_glow_base_modulate: Color = Color.WHITE
var _end_turn_glow_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	Events.damage_popup_requested.connect(spawn_damage_popup)
	_end_turn_base_modulate = end_turn_button.modulate
	_end_turn_base_scale = end_turn_button.scale
	end_turn_button.resized.connect(func(): end_turn_button.pivot_offset = end_turn_button.size * 0.5)
	await get_tree().process_frame
	end_turn_button.pivot_offset = end_turn_button.size * 0.5
	_setup_end_turn_glow()
#	Events.connect("combat_text_emitted", Callable(self, "_on_combat_text_emitted"))


func _set_char_stats(value: CharacterStats) -> void:
	if char_stats and char_stats.stats_changed.is_connected(_on_char_stats_changed):
		char_stats.stats_changed.disconnect(_on_char_stats_changed)

	char_stats = value
	stamina_ui.char_stats = char_stats
	hand.char_stats = char_stats
	hand.player_node = get_parent()  # 👈 likely the CombatPlayer node

	if char_stats and not char_stats.stats_changed.is_connected(_on_char_stats_changed):
		char_stats.stats_changed.connect(_on_char_stats_changed)

	_update_end_turn_attention_state()


func _on_player_hand_drawn() -> void:
	_is_player_turn = true
	end_turn_button.disabled = false
	_update_end_turn_attention_state()


func _on_end_turn_button_pressed() -> void:
	_is_player_turn = false
	end_turn_button.disabled = true
	_stop_end_turn_pulse()
	Events.player_turn_ended.emit()


func _on_char_stats_changed() -> void:
	_update_end_turn_attention_state()


func _update_end_turn_attention_state() -> void:
	if end_turn_button == null:
		return

	var should_pulse := _is_player_turn \
		and not end_turn_button.disabled \
		and char_stats != null \
		and char_stats.stamina <= 0

	if should_pulse:
		_start_end_turn_pulse()
	else:
		_stop_end_turn_pulse()


func _start_end_turn_pulse() -> void:
	if _end_turn_pulse_tween and _end_turn_pulse_tween.is_valid():
		return

	end_turn_button.modulate = _end_turn_base_modulate
	end_turn_button.scale = _end_turn_base_scale
	if end_turn_glow:
		end_turn_glow.visible = true
		end_turn_glow.scale = _end_turn_glow_base_scale
		end_turn_glow.modulate = Color(
			end_turn_pulse_color.r,
			end_turn_pulse_color.g,
			end_turn_pulse_color.b,
			end_turn_glow_min_alpha
		)

	_end_turn_pulse_tween = create_tween()
	_end_turn_pulse_tween.set_loops()
	_end_turn_pulse_tween.set_ease(Tween.EASE_IN_OUT)
	_end_turn_pulse_tween.set_trans(Tween.TRANS_SINE)

	# Phase 1: scale up + glow in (parallel)
	_end_turn_pulse_tween.tween_property(end_turn_button, "scale", end_turn_pulse_scale, end_turn_pulse_duration)
	if end_turn_glow:
		_end_turn_pulse_tween.parallel().tween_property(end_turn_glow, "scale", end_turn_glow_pulse_scale, end_turn_pulse_duration)
		_end_turn_pulse_tween.parallel().tween_property(end_turn_glow, "modulate:a", end_turn_glow_max_alpha, end_turn_pulse_duration)

	# Phase 2: scale down + glow out (runs after phase 1, parallel within)
	_end_turn_pulse_tween.tween_property(end_turn_button, "scale", _end_turn_base_scale, end_turn_pulse_duration)
	if end_turn_glow:
		_end_turn_pulse_tween.parallel().tween_property(end_turn_glow, "scale", _end_turn_glow_base_scale, end_turn_pulse_duration)
		_end_turn_pulse_tween.parallel().tween_property(end_turn_glow, "modulate:a", end_turn_glow_min_alpha, end_turn_pulse_duration)


func _stop_end_turn_pulse() -> void:
	if _end_turn_pulse_tween and _end_turn_pulse_tween.is_valid():
		_end_turn_pulse_tween.kill()

	_end_turn_pulse_tween = null

	if end_turn_button == null:
		return

	end_turn_button.modulate = _end_turn_base_modulate
	end_turn_button.scale = _end_turn_base_scale
	if end_turn_glow:
		end_turn_glow.scale = _end_turn_glow_base_scale
		end_turn_glow.modulate = _end_turn_glow_base_modulate
		end_turn_glow.visible = false


func _setup_end_turn_glow() -> void:
	if end_turn_glow == null:
		return

	_end_turn_glow_base_modulate = Color(end_turn_pulse_color.r, end_turn_pulse_color.g, end_turn_pulse_color.b, 0.0)
	_end_turn_glow_base_scale = end_turn_glow.scale
	end_turn_glow.resized.connect(func(): end_turn_glow.pivot_offset = end_turn_glow.size * 0.5)
	end_turn_glow.pivot_offset = end_turn_glow.size * 0.5
	end_turn_glow.modulate = _end_turn_glow_base_modulate
	end_turn_glow.z_index = 1
	end_turn_glow.visible = false


func set_run_enabled(can_run: bool) -> void:
	if run_button:
		run_button.disabled = not can_run
	else:
		push_warning("⚠️ CombatUI: Run button not found, could not apply run enabled state.")


func spawn_damage_popup(world_position: Vector2, amount: int, effect_type: String) -> void:
	var popup := preload("uid://b333pim2vobex").instantiate()
	print("popup instansiated")
	get_tree().current_scene.add_child(popup)

	popup.global_position = world_position
	var color: Color = Color.WHITE
	match effect_type:
		"damage": color = Color.DARK_RED
		"damage_blocked": color = Color.GRAY
		"heal": color = Color.WEB_GREEN
		"block": color = Color.ROYAL_BLUE
		"armor_absorbed": color = Color(0.8, 0.6, 0.2)

	popup.setup(amount, color)



#func _on_combat_text_emitted(message: String) -> void:
#	combat_text.append_text(message + "\n")
#	combat_text.scroll_to_line(combat_text.get_line_count())
