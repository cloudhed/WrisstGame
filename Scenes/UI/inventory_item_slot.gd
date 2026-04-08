class_name InventoryItemSlot
extends HBoxContainer

signal slot_clicked(slot: InventoryItemSlot)

## The inventory item this slot represents.
var item: InventoryItem
## How many of this item are in this slot.
var amount: int = 1
## Whether this item is currently equipped by the player.
var is_equipped: bool = false

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var equip_label: Label = %EquipLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_display()


func setup(p_item: InventoryItem, p_amount: int, p_equipped: bool) -> void:
	item = p_item
	amount = p_amount
	is_equipped = p_equipped
	if is_node_ready():
		_update_display()


func _update_display() -> void:
	if item == null:
		return
	icon_rect.texture = item.icon
	var display_name: String = item.name
	if item.is_stackable and amount > 1:
		display_name += " x%d" % amount
	name_label.text = display_name
	equip_label.visible = is_equipped
	_apply_modulate()


func _apply_modulate() -> void:
	if is_equipped:
		modulate = Color(1.2, 1.1, 0.7, 1.0)
	else:
		modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			slot_clicked.emit(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		modulate = Color(1.4, 1.3, 0.8, 1.0)
		_show_tooltip()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_apply_modulate()
		Events.tooltip_hide_requested.emit()


func _show_tooltip() -> void:
	if item == null:
		return
	var tip_text: String = item.description if not item.description.is_empty() else item.name
	Events.tile_tooltip_requested.emit(
		item.icon,
		tip_text,
		item.name,
		global_position,
		size
	)
