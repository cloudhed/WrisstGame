class_name QuantityPopup
extends PanelContainer

signal quantity_confirmed(amount: int)
signal quantity_cancelled

var min_amount: int = 1
var max_amount: int = 99
var current_amount: int = 1

@onready var quantity_label: Label = %QuantityLabel
@onready var minus_button: Button = %MinusButton
@onready var plus_button: Button = %PlusButton
@onready var max_button: Button = %MaxButton
@onready var ok_button: Button = %OKButton
@onready var cancel_button: Button = %CancelButton


func _ready() -> void:
	minus_button.pressed.connect(_on_minus)
	plus_button.pressed.connect(_on_plus)
	max_button.pressed.connect(_on_max)
	ok_button.pressed.connect(_on_ok)
	cancel_button.pressed.connect(_on_cancel)
	visible = false


func show_popup(p_min: int, p_max: int, start: int = 1) -> void:
	min_amount = p_min
	max_amount = p_max
	current_amount = clampi(start, min_amount, max_amount)
	_refresh()
	visible = true
	# Center on screen
	var viewport_size: Vector2 = get_viewport_rect().size
	global_position = (viewport_size - size) * 0.5


func _refresh() -> void:
	quantity_label.text = str(current_amount)
	minus_button.disabled = current_amount <= min_amount
	plus_button.disabled = current_amount >= max_amount


func _on_minus() -> void:
	current_amount = maxi(current_amount - 1, min_amount)
	_refresh()


func _on_plus() -> void:
	current_amount = mini(current_amount + 1, max_amount)
	_refresh()


func _on_max() -> void:
	current_amount = max_amount
	_refresh()


func _on_ok() -> void:
	visible = false
	quantity_confirmed.emit(current_amount)


func _on_cancel() -> void:
	visible = false
	quantity_cancelled.emit()


func _gui_input(event: InputEvent) -> void:
	# Block clicks from passing through the popup
	if event is InputEventMouseButton:
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_cancel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		_on_ok()
		get_viewport().set_input_as_handled()
