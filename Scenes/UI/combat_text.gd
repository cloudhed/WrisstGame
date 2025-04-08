extends Node

@onready var combat_text = $MarginContainer/CombatText as RichTextLabel


func _ready() -> void:
	print("CombatTextUI ready")
	Events.connect("combat_text_emitted", Callable(self, "_on_combat_text_emitted"))


func _on_combat_text_emitted(message: String) -> void:
	combat_text.append_text(message + "\n")
	combat_text.scroll_to_line(combat_text.get_line_count())
