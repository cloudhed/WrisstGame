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


#func _on_combat_text_emitted(message: String) -> void:
#	combat_text.append_text(message + "\n")
#	combat_text.scroll_to_line(combat_text.get_line_count())
