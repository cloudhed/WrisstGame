class_name InventoryItemSlot
extends PanelContainer

## One row in the inventory list.
##
## A click selects the row so the inspector can show it; a double click is a
## shortcut that equips or unequips directly, preserving the muscle memory from
## when a single click did that.

## Left click. Selects this row.
signal slot_clicked(slot: InventoryItemSlot)
## Double click. Equips or unequips without going via the inspector button.
signal slot_activated(slot: InventoryItemSlot)

## Whether hovering a row pops the shared tooltip.
##
## Off by default: the Item Inspector already shows this item's name, type,
## stats and description, so the tooltip only gets in the way of reading it.
## Tick this in inventory_item_slot.tscn to bring it back. Tiles have their own
## tooltip via tile_grid_card.gd and are unaffected either way.
@export var show_hover_tooltip: bool = false

## Painted behind the row. Assigned in the scene so no colour is hardcoded here.
@export var style_normal: StyleBox
@export var style_hover: StyleBox
@export var style_selected: StyleBox

## The inventory item this slot represents.
var item: InventoryItem
## How many of this item are in this slot.
var amount: int = 1
## Whether this item is currently equipped by the player.
var is_equipped: bool = false
## Whether this row is the one the inspector is showing.
var is_selected: bool = false

var _hovered: bool = false

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


func set_selected(selected: bool) -> void:
	is_selected = selected
	if is_node_ready():
		_apply_visual_state()


## Cheap in-place refresh for the equip path, so the whole list never has to be
## rebuilt just because one item changed hands.
func set_equipped(equipped: bool) -> void:
	is_equipped = equipped
	if is_node_ready():
		equip_label.visible = is_equipped
		_apply_name_color()


func _update_display() -> void:
	if item == null:
		return
	icon_rect.texture = item.icon
	var display_name: String = item.name
	if item.is_stackable and amount > 1:
		display_name += " x%d" % amount
	name_label.text = display_name
	equip_label.visible = is_equipped
	_apply_name_color()
	_apply_visual_state()


func _apply_name_color() -> void:
	var base := ItemCategory.color(ItemCategory.classify(item))
	name_label.add_theme_color_override(
		"font_color", base.lightened(0.25) if is_equipped else base)


## Selection wins over hover, so a selected row stays lit while the mouse moves
## across its neighbours.
##
## Deliberately not modulate: that tints children too, which would wash out both
## the gradient bar and the per-category name colours.
func _apply_visual_state() -> void:
	if is_selected:
		add_theme_stylebox_override("panel", style_selected)
	elif _hovered:
		add_theme_stylebox_override("panel", style_hover)
	else:
		add_theme_stylebox_override("panel", style_normal)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		if event.double_click:
			slot_activated.emit(self)
		else:
			slot_clicked.emit(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		_apply_visual_state()
		_show_tooltip()
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		_apply_visual_state()
		if show_hover_tooltip:
			Events.tooltip_hide_requested.emit()


func _show_tooltip() -> void:
	if not show_hover_tooltip or item == null:
		return
	var tip_text: String = item.description if not item.description.is_empty() else item.name
	Events.tile_tooltip_requested.emit(
		item.icon,
		tip_text,
		item.name,
		global_position,
		size
	)
