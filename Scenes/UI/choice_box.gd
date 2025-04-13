class_name ChoiceBox
extends Control

signal choice_selected(index: int)
@onready var button_container: VBoxContainer = $MarginContainer/ButtonContainer


func show_choices(options: Array):
	for child in button_container.get_children():
		child.queue_free()

	for i in options.size():
		var btn = Button.new()
		btn.text = options[i].text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.connect("pressed", _on_choice_pressed.bind(i))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button_container.add_child(btn)
		print("Added button! ")


func _on_choice_pressed(index: int):
	print("🔘 Choice pressed: ", index)  # Add this
	choice_selected.emit(index)
