class_name ChoiceBox
extends Control

signal choice_selected(index: int)

@onready var button_container: VBoxContainer = $MarginContainer/CenterContainer/ButtonContainer

var _was_showing: bool = false  # Tracks if a choice was on screen when UI was opened

# Circled number glyphs used as key-hint prefixes on choice buttons (➊ = key 1, etc.)
const CHOICE_LABELS: Array[String] = ["❶", "❷", "❸", "❹", "❺", "❻", "❼", "❽", "❾"]

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
		# Prefix with circled number glyph (➊ ➋ … ➒) if within range, plain number fallback beyond 9
		var label := CHOICE_LABELS[i] if i < CHOICE_LABELS.size() else str(i + 1) + "."
		btn.text = label + "  " + options[i].text
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


# ── Keyboard navigation ───────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	# Only intercept when the choice menu is active. When hidden, pass everything
	# through untouched so the rest of the game's input handling works normally.
	if not visible or GameUI.is_ui_open():
		return

	# Only react to key-down events — not key-release, not held-key repeat.
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return

	var buttons: Array[Node] = button_container.get_children()
	if buttons.is_empty():
		return

	# ── Number keys 1–9: jump directly to that choice ──────────────────────
	# Works for both the top-row digit keys and the numpad.
	var num_index: int = _get_number_key_index(event.keycode)
	if num_index != -1 and num_index < buttons.size():
		get_viewport().set_input_as_handled()
		_on_choice_pressed(num_index)  # Same code path as a mouse click
		return

	# ── Arrow keys: navigate focus through the vertical choice list ─────────
	# All four directions are handled here because Godot's built-in focus
	# traversal doesn't reliably reach dynamically-created buttons in this setup.
	# Up/Left both move toward choice 0; Down/Right move away from it.
	if event.is_action("ui_up") or event.is_action("ui_left"):
		get_viewport().set_input_as_handled()
		_navigate_focus(-1, buttons)
		return

	if event.is_action("ui_down") or event.is_action("ui_right"):
		get_viewport().set_input_as_handled()
		_navigate_focus(1, buttons)
		return


## Returns the 0-based choice index for number keys 1–9 (top row and numpad).
## Returns -1 if the key is not a usable number key (e.g. 0, or any other key).
func _get_number_key_index(keycode: Key) -> int:
	# Top-row digits: KEY_1 = 49, KEY_2 = 50, … KEY_9 = 57
	if keycode >= KEY_1 and keycode <= KEY_9:
		return keycode - KEY_1  # KEY_1 → index 0, KEY_9 → index 8

	# Numpad digits: KEY_KP_1 … KEY_KP_9 (KEY_KP_0 is excluded automatically)
	if keycode >= KEY_KP_1 and keycode <= KEY_KP_9:
		return keycode - KEY_KP_1  # Same offset logic as above

	return -1  # Not a number key we care about


## Moves keyboard focus by `direction` steps (+1 = next/down, -1 = prev/up).
## Wraps around: pressing up on the first choice lands on the last, and vice versa.
func _navigate_focus(direction: int, buttons: Array[Node]) -> void:
	var current_focused: Control = get_viewport().gui_get_focus_owner()

	# Walk the button list to find which one (if any) currently has focus.
	var current_index: int = -1
	for i in buttons.size():
		if buttons[i] == current_focused:
			current_index = i
			break

	# If no choice button is focused, land on a sensible default rather than
	# doing unpredictable modulo arithmetic from a -1 base.
	if current_index == -1:
		var fallback := 0 if direction > 0 else buttons.size() - 1
		(buttons[fallback] as Button).grab_focus()
		return

	# Wrap-around using modulo. GDScript follows Python-style modulo, so
	# (-1) % n correctly returns (n - 1), giving us free wrap-to-last.
	var next_index: int = (current_index + direction) % buttons.size()
	var target: Button = buttons[next_index] as Button
	if is_instance_valid(target) and target.is_inside_tree():
		target.grab_focus()
