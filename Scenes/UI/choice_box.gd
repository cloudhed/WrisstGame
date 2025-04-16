class_name ChoiceBox
extends Control

signal choice_selected(index: int)

@onready var button_container: VBoxContainer = $MarginContainer/CenterContainer/ButtonContainer

func show_choices(options: Array) -> void:
	# Clear previous buttons
	for child in button_container.get_children():
		child.queue_free()

	# Add new buttons
	var new_buttons: Array = []

	for i in options.size():
		var btn := Button.new()
		btn.text = options[i].text
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_ALL
		btn.connect("pressed", _on_choice_pressed.bind(i))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button_container.add_child(btn)
		new_buttons.append(btn)

	# Wait for layout pass
	await get_tree().process_frame

	# Focus only if buttons still exist and are valid
	if new_buttons.size() > 0:
		var first_button: Button = new_buttons[0]
		if is_instance_valid(first_button) and first_button.is_inside_tree():
			first_button.grab_focus()


func _on_choice_pressed(index: int) -> void:
	print("🔘 Choice pressed: ", index)
	choice_selected.emit(index)
