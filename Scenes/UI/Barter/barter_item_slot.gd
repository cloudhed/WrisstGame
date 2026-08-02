class_name BarterItemSlot
extends HBoxContainer

signal slot_clicked(slot: BarterItemSlot)
signal slot_right_clicked(slot: BarterItemSlot)
signal slot_hovered(slot: BarterItemSlot)
signal slot_unhovered(slot: BarterItemSlot)

## The inventory item this slot represents.
var item: InventoryItem
## How many of this item are in this slot.
var amount: int = 1
## For shop items, a reference to the ShopItemEntry for buy pricing.
var shop_entry: ShopItemEntry
## Which panel this slot belongs to: "player", "shop", or "barter".
var source: String = "player"
## If in barter window, the original side: "player" or "shop".
var origin: String = ""
## Whether this item is currently equipped by the player.
var is_equipped: bool = false

@onready var icon_rect: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var price_label: Label = %PriceLabel
@onready var direction_arrow: Label = %DirectionArrow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_update_display()


func setup(p_item: InventoryItem, p_amount: int, p_source: String, p_shop_entry: ShopItemEntry = null) -> void:
	item = p_item
	amount = p_amount
	source = p_source
	shop_entry = p_shop_entry
	is_equipped = _check_equipped()

	if is_node_ready():
		_update_display()


func _update_display() -> void:
	if item == null:
		return

	icon_rect.texture = item.icon

	# Build name string
	var display_name: String = item.name
	if amount > 1:
		display_name += " x%d" % amount
	if is_equipped:
		display_name += " [E]"
	name_label.text = display_name

	# Price label
	var price_parts: Array[String] = []
	if source == "shop" or origin == "shop":
		# Show buy price from shop entry
		if shop_entry:
			if shop_entry.buy_price_ore > 0:
				price_parts.append("%d öre" % (shop_entry.buy_price_ore * amount))
			if shop_entry.buy_price_crowns > 0:
				price_parts.append("%d cr" % (shop_entry.buy_price_crowns * amount))
			if shop_entry.buy_price_drots > 0:
				price_parts.append("%d dr" % (shop_entry.buy_price_drots * amount))
	else:
		# Show sell price
		if item.sell_price_ore > 0:
			price_parts.append("%d öre" % (item.sell_price_ore * amount))
		if item.sell_price_crowns > 0:
			price_parts.append("%d cr" % (item.sell_price_crowns * amount))
		if item.sell_price_drots > 0:
			price_parts.append("%d dr" % (item.sell_price_drots * amount))
	price_label.text = ", ".join(price_parts) if not price_parts.is_empty() else "no value"

	# Direction arrow (only visible in barter window)
	if source == "barter":
		direction_arrow.visible = true
		direction_arrow.text = ">>>" if origin == "player" else "<<<"
	else:
		direction_arrow.visible = false

	# Gray out equipped items
	if is_equipped and source == "player":
		modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		modulate = Color.WHITE


func _check_equipped() -> bool:
	if not item is EquipableItem:
		return false
	var equip := item as EquipableItem
	return (
		equip == GameState.equipped_weapon
		or equip == GameState.equipped_armor
		or equip == GameState.equipped_offhand
		or equip in GameState.equipped_trinkets
	)


## Whether this slot is currently "focused" for inspection.
var is_focused: bool = false


func set_focused(focused: bool) -> void:
	is_focused = focused
	if is_focused:
		modulate = Color(1.5, 1.3, 0.7, 1.0)
	elif is_equipped and source == "player":
		modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		modulate = Color.WHITE


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			slot_clicked.emit(self)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			accept_event()
			slot_right_clicked.emit(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		slot_hovered.emit(self)
		_show_item_tooltip()
	elif what == NOTIFICATION_MOUSE_EXIT:
		slot_unhovered.emit(self)
		Events.tooltip_hide_requested.emit()


func _show_item_tooltip() -> void:
	if item == null:
		return
	var tip_text: String = item.description if not item.description.is_empty() else item.name
	var price_info: String = _build_price_tooltip()
	if not price_info.is_empty():
		tip_text += "\n" + price_info
	Events.tile_tooltip_requested.emit(
		item.icon,
		tip_text,
		item.name,
		global_position,
		size
	)


func _build_price_tooltip() -> String:
	var parts: Array[String] = []
	if source == "shop" or origin == "shop":
		if shop_entry:
			if shop_entry.buy_price_ore > 0:
				parts.append("%d öre" % shop_entry.buy_price_ore)
			if shop_entry.buy_price_crowns > 0:
				parts.append("%d cr" % shop_entry.buy_price_crowns)
			if shop_entry.buy_price_drots > 0:
				parts.append("%d dr" % shop_entry.buy_price_drots)
		if not parts.is_empty():
			return "Buy: " + ", ".join(parts)
	else:
		if item.sell_price_ore > 0:
			parts.append("%d öre" % item.sell_price_ore)
		if item.sell_price_crowns > 0:
			parts.append("%d cr" % item.sell_price_crowns)
		if item.sell_price_drots > 0:
			parts.append("%d dr" % item.sell_price_drots)
		if not parts.is_empty():
			return "Sell: " + ", ".join(parts)
	return ""
