class_name ChoiceBox
extends Control

signal choice_selected(index: int)

@onready var button_container: VBoxContainer = $MarginContainer/CenterContainer/ButtonContainer

var _was_showing: bool = false  # Tracks if a choice was on screen when UI was opened

func _process(_delta: float) -> void:
	var is_ui_open = GameUI.is_ui_open()

	# When UI is open, hide and block input
	if is_ui_open:
		if visible:
			_was_showing = true
		visible = false
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		# If we were showing before, show again
		if _was_showing:
			visible = true
			_was_showing = false

			# Auto-refocus first button
			await get_tree().process_frame
			var buttons = button_container.get_children()
			if buttons.size() > 0:
				var first_button: Button = buttons[0]
				if is_instance_valid(first_button) and first_button.is_inside_tree():
					first_button.grab_focus()

		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP


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
