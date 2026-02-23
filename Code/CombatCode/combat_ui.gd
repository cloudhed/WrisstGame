class_name CombatUI
extends CanvasLayer

@export var char_stats: CharacterStats : set = _set_char_stats

@onready var hand: Hand = $Hand as Hand
@onready var stamina_ui: StaminaUI = $StaminaUI as StaminaUI
@onready var end_turn_button: Button = %EndTurnButton
#@onready var combat_text = $StatsUIManager/CombatTextUI/MarginContainer/CombatText as RichTextLabel

func _ready() -> void:
	Events.player_hand_drawn.connect(_on_player_hand_drawn)
	end_turn_button.pressed.connect(_on_end_turn_button_pressed)
	Events.damage_popup_requested.connect(spawn_damage_popup)
#	Events.connect("combat_text_emitted", Callable(self, "_on_combat_text_emitted"))


func _set_char_stats(value: CharacterStats) -> void:
	char_stats = value
	stamina_ui.char_stats = char_stats
	hand.char_stats = char_stats
	hand.player_node = get_parent()  # 👈 likely the CombatPlayer node


func _on_player_hand_drawn() -> void:
	end_turn_button.disabled = false


func _on_end_turn_button_pressed() -> void:
	end_turn_button.disabled = true
	Events.player_turn_ended.emit()


func spawn_damage_popup(world_position: Vector2, amount: int, effect_type: String) -> void:
	var popup := preload("uid://b333pim2vobex").instantiate()
	print("popup instansiated")
	get_tree().current_scene.add_child(popup)

	popup.global_position = world_position
	var color: Color = Color.WHITE
	match effect_type:
		"damage": color = Color.DARK_RED
		"heal": color = Color.WEB_GREEN
		"block": color = Color.ROYAL_BLUE

	popup.setup(amount, color)



#func _on_combat_text_emitted(message: String) -> void:
#	combat_text.append_text(message + "\n")
#	combat_text.scroll_to_line(combat_text.get_line_count())
