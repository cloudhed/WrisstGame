class_name BarterScreen
extends Control

signal barter_closed

const BARTER_ITEM_SLOT_PATH := "res://Scenes/UI/Barter/barter_item_slot.tscn"
const TILE_GRID_CARD_PATH := "res://Scenes/TileUI/tile_grid_card.tscn"

var shop_inventory: ShopInventory
## Items the player is selling: [{item: InventoryItem, amount: int}]
var barter_selling: Array = []
## Items the player is buying: [{shop_entry: ShopItemEntry, amount: int}]
var barter_buying: Array = []

var _slot_scene: PackedScene
var _tile_card_scene: PackedScene

# --- Node references ---
@onready var player_ore_label: Label = %PlayerOreLabel
@onready var player_crowns_label: Label = %PlayerCrownsLabel
@onready var player_drots_label: Label = %PlayerDrotsLabel

@onready var balance_ore_label: Label = %BalanceOreLabel
@onready var balance_crowns_label: Label = %BalanceCrownsLabel
@onready var balance_drots_label: Label = %BalanceDrotsLabel

@onready var shop_name_label: Label = %ShopNameLabel

@onready var player_item_list: VBoxContainer = %PlayerItemList
@onready var barter_item_list: VBoxContainer = %BarterItemList
@onready var shop_item_list: VBoxContainer = %ShopItemList

@onready var tile_preview_grid: GridContainer = %TilePreviewGrid
@onready var tile_preview_label: Label = %TilePreviewLabel

@onready var confirm_button: Button = %ConfirmButton
@onready var leave_button: Button = %LeaveButton
@onready var quantity_popup: QuantityPopup = %QuantityPopup

@onready var equipped_message_label: Label = %EquippedMessage

## The currently right-click-focused slot (pins tile preview).
var focused_slot: BarterItemSlot = null


func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)
	leave_button.pressed.connect(_on_leave_pressed)
	quantity_popup.visible = false


func open(shop: ShopInventory) -> void:
	# Fix 5: Reset cursor in case a hotspot cursor was stuck
	Input.set_custom_mouse_cursor(null)
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

	shop_inventory = shop
	barter_selling.clear()
	barter_buying.clear()
	_load_scenes()
	_refresh_all()
	visible = true


# --- Scene loading (lazy) ---

func _load_scenes() -> void:
	if _slot_scene == null:
		_slot_scene = load(BARTER_ITEM_SLOT_PATH) as PackedScene
	if _tile_card_scene == null:
		_tile_card_scene = load(TILE_GRID_CARD_PATH) as PackedScene


# --- Full refresh ---

func _refresh_all() -> void:
	# Slots are rebuilt, so clear any stale focus reference
	focused_slot = null
	_refresh_player_currency()
	_refresh_player_items()
	_refresh_shop_items()
	_refresh_barter_items()
	_recalculate_balance()
	_clear_tile_preview()
	_update_shop_name()
	equipped_message_label.visible = false


func _update_shop_name() -> void:
	if shop_inventory:
		shop_name_label.text = shop_inventory.shop_name


# --- Currency display ---

func _refresh_player_currency() -> void:
	player_ore_label.text = "Öre: %d" % GameState.player_ore
	player_crowns_label.text = "Crowns: %d" % GameState.player_crowns
	player_drots_label.text = "Drots: %d" % GameState.player_drots


# --- Player inventory panel ---

func _refresh_player_items() -> void:
	_clear_children(player_item_list)

	for slot in GameState.player_inventory:
		var item: InventoryItem = slot.item
		var amount: int = slot.amount

		if item.hidden_from_inventory:
			continue
		if not item.is_sellable():
			continue

		# Subtract amount already in barter
		var barter_amount: int = _get_selling_amount(item)
		var available: int = amount - barter_amount
		if available <= 0:
			continue

		var slot_node: BarterItemSlot = _slot_scene.instantiate() as BarterItemSlot
		player_item_list.add_child(slot_node)
		slot_node.setup(item, available, "player")
		slot_node.slot_clicked.connect(_on_player_item_clicked)
		slot_node.slot_right_clicked.connect(_on_slot_right_clicked)
		slot_node.slot_hovered.connect(_on_slot_hovered)
		slot_node.slot_unhovered.connect(_on_slot_unhovered)


# --- Shop inventory panel ---

func _refresh_shop_items() -> void:
	_clear_children(shop_item_list)

	if shop_inventory == null:
		return

	for entry in shop_inventory.shop_items:
		if entry.item == null:
			continue

		# Skip out-of-stock items
		var barter_amount: int = _get_buying_amount(entry)
		var available: int = entry.stock - barter_amount if entry.stock >= 0 else 99
		if available <= 0:
			continue

		# Skip unique items already purchased (stock was set to 0)
		if entry.is_unique and entry.stock == 0:
			continue

		var slot_node: BarterItemSlot = _slot_scene.instantiate() as BarterItemSlot
		shop_item_list.add_child(slot_node)
		slot_node.setup(entry.item, available, "shop", entry)
		slot_node.slot_clicked.connect(_on_shop_item_clicked)
		slot_node.slot_right_clicked.connect(_on_slot_right_clicked)
		slot_node.slot_hovered.connect(_on_slot_hovered)
		slot_node.slot_unhovered.connect(_on_slot_unhovered)


# --- Barter window panel ---

func _refresh_barter_items() -> void:
	_clear_children(barter_item_list)

	# Selling entries (player items going to shop)
	for entry in barter_selling:
		var slot_node: BarterItemSlot = _slot_scene.instantiate() as BarterItemSlot
		barter_item_list.add_child(slot_node)
		slot_node.setup(entry.item, entry.amount, "barter")
		slot_node.origin = "player"
		# Re-run display to show the arrow after setting origin
		slot_node._update_display()
		slot_node.slot_clicked.connect(_on_barter_item_clicked)
		slot_node.slot_right_clicked.connect(_on_slot_right_clicked)
		slot_node.slot_hovered.connect(_on_slot_hovered)
		slot_node.slot_unhovered.connect(_on_slot_unhovered)

	# Buying entries (shop items coming to player)
	for entry in barter_buying:
		var slot_node: BarterItemSlot = _slot_scene.instantiate() as BarterItemSlot
		barter_item_list.add_child(slot_node)
		slot_node.setup(entry.shop_entry.item, entry.amount, "barter", entry.shop_entry)
		slot_node.origin = "shop"
		slot_node._update_display()
		slot_node.slot_clicked.connect(_on_barter_item_clicked)
		slot_node.slot_right_clicked.connect(_on_slot_right_clicked)
		slot_node.slot_hovered.connect(_on_slot_hovered)
		slot_node.slot_unhovered.connect(_on_slot_unhovered)


# --- Click handlers ---

func _on_player_item_clicked(slot: BarterItemSlot) -> void:
	if slot.is_equipped:
		_show_equipped_message()
		return

	if slot.item.is_stackable and slot.amount > 1:
		_show_quantity_popup(slot.item, 1, slot.amount, "_add_to_selling")
	else:
		_add_to_selling(slot.item, 1)


func _on_shop_item_clicked(slot: BarterItemSlot) -> void:
	var available: int = slot.amount
	if slot.item.is_stackable and available > 1:
		_show_quantity_popup(slot.item, 1, available, "_add_to_buying", slot.shop_entry)
	else:
		_add_to_buying(slot.shop_entry, 1)


func _on_barter_item_clicked(slot: BarterItemSlot) -> void:
	if slot.origin == "player":
		_remove_from_selling(slot.item, slot.amount)
	elif slot.origin == "shop":
		_remove_from_buying(slot.shop_entry, slot.amount)


# --- Right-click focus (inspect) ---

func _on_slot_right_clicked(slot: BarterItemSlot) -> void:
	if focused_slot == slot:
		_unfocus_slot()
		return
	_unfocus_slot()
	focused_slot = slot
	slot.set_focused(true)
	_show_tile_preview(slot.item)


func _unfocus_slot() -> void:
	if focused_slot != null:
		focused_slot.set_focused(false)
		focused_slot = null
	_clear_tile_preview()


# --- Quantity popup ---

var _pending_callback: String = ""
var _pending_item: InventoryItem
var _pending_shop_entry: ShopItemEntry

func _show_quantity_popup(item: InventoryItem, p_min: int, p_max: int, callback: String, shop_entry: ShopItemEntry = null) -> void:
	_pending_callback = callback
	_pending_item = item
	_pending_shop_entry = shop_entry

	# Disconnect previous signals to avoid stacking
	if quantity_popup.quantity_confirmed.is_connected(_on_quantity_confirmed):
		quantity_popup.quantity_confirmed.disconnect(_on_quantity_confirmed)
	if quantity_popup.quantity_cancelled.is_connected(_on_quantity_cancelled):
		quantity_popup.quantity_cancelled.disconnect(_on_quantity_cancelled)

	quantity_popup.quantity_confirmed.connect(_on_quantity_confirmed, CONNECT_ONE_SHOT)
	quantity_popup.quantity_cancelled.connect(_on_quantity_cancelled, CONNECT_ONE_SHOT)
	quantity_popup.show_popup(p_min, p_max)


func _on_quantity_confirmed(amount: int) -> void:
	match _pending_callback:
		"_add_to_selling":
			_add_to_selling(_pending_item, amount)
		"_add_to_buying":
			_add_to_buying(_pending_shop_entry, amount)
	_pending_callback = ""


func _on_quantity_cancelled() -> void:
	_pending_callback = ""


# --- Barter array manipulation ---

func _add_to_selling(item: InventoryItem, amount: int) -> void:
	# Check if already in barter_selling, merge
	for entry in barter_selling:
		if entry.item == item:
			entry.amount += amount
			_after_barter_change()
			return
	barter_selling.append({item = item, amount = amount})
	_after_barter_change()


func _remove_from_selling(item: InventoryItem, amount: int) -> void:
	for i in barter_selling.size():
		if barter_selling[i].item == item:
			barter_selling[i].amount -= amount
			if barter_selling[i].amount <= 0:
				barter_selling.remove_at(i)
			_after_barter_change()
			return


func _add_to_buying(shop_entry: ShopItemEntry, amount: int) -> void:
	for entry in barter_buying:
		if entry.shop_entry == shop_entry:
			entry.amount += amount
			_after_barter_change()
			return
	barter_buying.append({shop_entry = shop_entry, amount = amount})
	_after_barter_change()


func _remove_from_buying(shop_entry: ShopItemEntry, amount: int) -> void:
	for i in barter_buying.size():
		if barter_buying[i].shop_entry == shop_entry:
			barter_buying[i].amount -= amount
			if barter_buying[i].amount <= 0:
				barter_buying.remove_at(i)
			_after_barter_change()
			return


func _after_barter_change() -> void:
	_refresh_player_items()
	_refresh_shop_items()
	_refresh_barter_items()
	_recalculate_balance()


# --- Balance calculation ---

func _recalculate_balance() -> void:
	var balance: Dictionary = _calculate_balance()

	_format_balance_label(balance_ore_label, balance.ore, "öre")
	_format_balance_label(balance_crowns_label, balance.crowns, "cr")
	_format_balance_label(balance_drots_label, balance.drots, "dr")

	confirm_button.disabled = not _can_confirm_trade()


func _calculate_balance() -> Dictionary:
	var balance := {ore = 0, crowns = 0, drots = 0}

	for entry in barter_selling:
		balance.ore += entry.item.sell_price_ore * entry.amount
		balance.crowns += entry.item.sell_price_crowns * entry.amount
		balance.drots += entry.item.sell_price_drots * entry.amount

	for entry in barter_buying:
		balance.ore -= entry.shop_entry.buy_price_ore * entry.amount
		balance.crowns -= entry.shop_entry.buy_price_crowns * entry.amount
		balance.drots -= entry.shop_entry.buy_price_drots * entry.amount

	return balance


func _format_balance_label(label: Label, value: int, suffix: String) -> void:
	if value > 0:
		label.text = "+%d %s" % [value, suffix]
		label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.3, 1.0))
	elif value < 0:
		label.text = "%d %s" % [value, suffix]
		label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))
	else:
		label.text = "0 %s" % suffix
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))


# --- Trade validation ---

func _can_confirm_trade() -> bool:
	if barter_selling.is_empty() and barter_buying.is_empty():
		return false

	var balance: Dictionary = _calculate_balance()

	# Player must afford the deficit in each currency
	if GameState.player_ore + balance.ore < 0:
		return false
	if GameState.player_crowns + balance.crowns < 0:
		return false
	if GameState.player_drots + balance.drots < 0:
		return false

	return true


# --- Confirm trade ---

func _on_confirm_pressed() -> void:
	if not _can_confirm_trade():
		return

	# 1. Remove sold items from player inventory
	for entry in barter_selling:
		GameState.remove_item(entry.item, entry.amount)

	# 1b. Add sold items to the shop inventory (buyback)
	for entry in barter_selling:
		_add_sold_item_to_shop(entry.item, entry.amount)

	# 2. Add bought items to player inventory
	for entry in barter_buying:
		GameState.add_item(entry.shop_entry.item, entry.amount)
		# Decrement shop stock if limited
		if entry.shop_entry.stock >= 0:
			entry.shop_entry.stock -= entry.amount

	# 3. Apply currency changes
	var balance: Dictionary = _calculate_balance()
	_apply_currency_change("ore", balance.ore)
	_apply_currency_change("crowns", balance.crowns)
	_apply_currency_change("drots", balance.drots)

	# Stay in shop — clear barter arrays and refresh panels
	barter_selling.clear()
	barter_buying.clear()
	_refresh_all()


func _apply_currency_change(currency: String, net: int) -> void:
	if net == 0:
		return
	match currency:
		"ore":
			if net > 0:
				GameState.add_ore(net)
			else:
				GameState.remove_ore(abs(net))
		"crowns":
			if net > 0:
				GameState.add_crowns(net)
			else:
				GameState.remove_crowns(abs(net))
		"drots":
			if net > 0:
				GameState.add_drots(net)
			else:
				GameState.remove_drots(abs(net))


# --- Cancel / Close ---

func _on_leave_pressed() -> void:
	_close_barter()


func _close_barter() -> void:
	barter_selling.clear()
	barter_buying.clear()
	visible = false
	barter_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if quantity_popup.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		# First Escape unfocuses; second Escape closes barter
		if focused_slot != null:
			_unfocus_slot()
			get_viewport().set_input_as_handled()
			return
		_on_leave_pressed()
		get_viewport().set_input_as_handled()


# --- Equipped item message ---

func _show_equipped_message() -> void:
	equipped_message_label.text = "Unequip this item first."
	equipped_message_label.visible = true
	# Auto-hide after 2 seconds
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func(): equipped_message_label.visible = false)


# --- Tile preview ---

func _on_slot_hovered(slot: BarterItemSlot) -> void:
	# Don't override pinned tile preview while a slot is focused
	if focused_slot == null:
		_show_tile_preview(slot.item)


func _on_slot_unhovered(_slot: BarterItemSlot) -> void:
	if focused_slot == null:
		_clear_tile_preview()


func _show_tile_preview(item: InventoryItem) -> void:
	_clear_tile_preview()

	if not item is EquipableItem:
		tile_preview_label.text = "Equipment Tiles"
		return

	var equip := item as EquipableItem
	if equip.tile_bundle == null or equip.tile_bundle.tiles.is_empty():
		tile_preview_label.text = "Equipment Tiles"
		return

	tile_preview_label.text = "%s — Tiles" % item.name

	for tile in equip.tile_bundle.tiles:
		var card: Node = _tile_card_scene.instantiate()
		card.tile = tile
		tile_preview_grid.add_child(card)


func _clear_tile_preview() -> void:
	tile_preview_label.text = "Equipment Tiles"
	for child in tile_preview_grid.get_children():
		child.queue_free()


# --- Helpers ---

func _get_selling_amount(item: InventoryItem) -> int:
	for entry in barter_selling:
		if entry.item == item:
			return entry.amount
	return 0


func _get_buying_amount(shop_entry: ShopItemEntry) -> int:
	for entry in barter_buying:
		if entry.shop_entry == shop_entry:
			return entry.amount
	return 0


## Adds a sold item into the shop's inventory for buyback.
## If the shop already stocks this item, increments the existing stock.
## Otherwise, creates a new ShopItemEntry with auto-calculated markup pricing.
func _add_sold_item_to_shop(item: InventoryItem, amount: int) -> void:
	for entry in shop_inventory.shop_items:
		if entry.item == item:
			if entry.stock >= 0:
				entry.stock += amount
			return  # unlimited (-1) stays unlimited

	# Create new entry with markup pricing
	var new_entry := ShopItemEntry.new()
	new_entry.item = item
	new_entry.stock = amount
	new_entry.is_unique = false
	var markup: float = shop_inventory.markup_percent
	new_entry.buy_price_ore = ceili(item.sell_price_ore * (1.0 + markup / 100.0))
	new_entry.buy_price_crowns = ceili(item.sell_price_crowns * (1.0 + markup / 100.0))
	new_entry.buy_price_drots = ceili(item.sell_price_drots * (1.0 + markup / 100.0))
	shop_inventory.shop_items.append(new_entry)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
