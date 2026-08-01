class_name InventoryScreen
extends Panel

## Controller for the inventory screen: the item list, the equipment summary,
## the currency readout and the tile pile preview.
##
## Lives on UIContainer/InventoryScreen inside GameUI.tscn. Screen routing,
## input handling and the notification toasts stay on ui_manager.gd, which owns
## this node and calls open() / close() on it.

## Emitted when the screen closes by any route, so the host can re-enable the
## world hotspots it disabled on open.
signal inventory_closed

const INVENTORY_SLOT_SCENE_PATH := "res://Scenes/UI/inventory_item_slot.tscn"
const CATEGORY_SECTION_SCENE_PATH := "res://Scenes/UI/Inventory/inventory_category_section.tscn"

#-ITEM LIST-#
@onready var category_container: VBoxContainer = %CategoryContainer
@onready var item_scroll: ScrollContainer = %ScrollContainer

#-INSPECTOR-#
@onready var inspector: ItemInspector = %ItemInspector

#-HEADER-#
@onready var close_button: Button = %CloseButton

#-CURRENCY-#
@onready var current_ore_label: Label = %CurrentOreLabel
@onready var current_crowns_label: Label = %CurrentCrownsLabel
@onready var current_drots_label: Label = %CurrentDrotsLabel

#-EQUIPMENT SUMMARY-#
@onready var current_weapon_label: Label = %EquippedWeaponLabel
@onready var current_armor_label: Label = %EquippedArmorLabel
@onready var current_offhand_label: Label = %EquippedOffhandLabel
@onready var current_trinkets_label: Label = %EquippedTrinketsLabel

#-TILE PILE-#
@onready var tile_pile_panel: TilePilePanel = %TilePanel

var _inventory_slot_scene: PackedScene = null
var _category_section_scene: PackedScene = null

## Which sections are open, keyed by ItemCategory id. Kept in memory only: it
## survives closing and reopening the screen within a session and resets on
## restart. Deliberately not saved, because GameState.to_dict() is the game save
## and UI preferences do not belong in it.
var _category_expanded: Dictionary = {}

## The item the inspector is showing, held as a resource rather than a node
## because refresh() frees and rebuilds every row.
var _selected_item: InventoryItem = null

## Set when equipment changes while the screen is hidden, so the tile grid is
## rebuilt on the next open rather than every time the player swaps gear in a
## dialogue. GameUI is an autoload, so this also keeps the tile card scene out
## of memory until the player actually looks at the inventory.
var _tile_grid_dirty: bool = true


func _ready() -> void:
	visible = false
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP

	for category_id in ItemCategory.ORDER:
		_category_expanded[category_id] = true

	close_button.pressed.connect(close)
	inspector.equip_requested.connect(_on_equip_requested)
	inspector.unequip_requested.connect(_on_unequip_requested)

	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.state_restored.connect(_on_state_restored)
	GameState.fallback_equipped.connect(_on_equipment_changed)


# ──────────────────────────────────────────────────
# Open / close

func open() -> void:
	visible = true
	refresh()


func close() -> void:
	visible = false
	Events.tooltip_hide_requested.emit()
	inventory_closed.emit()


## Escape closes the screen instead of falling through to debug_panel.gd, which
## binds the same key to quitting the game. barter_screen.gd shields itself the
## same way. GameUI is a later autoload than DebugPanel, so it sees the event
## first and consuming it here is enough.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# ──────────────────────────────────────────────────
# Scene loading
#
# Loaded on first use rather than preloaded, because GameUI is an autoload and
# must not drag item and tile scenes into memory at boot.

func _get_inventory_slot_scene() -> PackedScene:
	if _inventory_slot_scene == null:
		_inventory_slot_scene = load(INVENTORY_SLOT_SCENE_PATH) as PackedScene
		if _inventory_slot_scene == null:
			push_error("❌ Failed to load inventory slot scene: " + INVENTORY_SLOT_SCENE_PATH)
	return _inventory_slot_scene


func _get_category_section_scene() -> PackedScene:
	if _category_section_scene == null:
		_category_section_scene = load(CATEGORY_SECTION_SCENE_PATH) as PackedScene
		if _category_section_scene == null:
			push_error("❌ Failed to load category section scene: " + CATEGORY_SECTION_SCENE_PATH)
	return _category_section_scene


# ──────────────────────────────────────────────────
# Item list

func refresh() -> void:
	var scroll_before := item_scroll.scroll_vertical

	# remove_child before queue_free, because a queued node stays in the tree
	# until the end of the frame. Two refreshes in one frame (a save load emits
	# both inventory_changed and state_restored) would otherwise duplicate rows.
	for child in category_container.get_children():
		category_container.remove_child(child)
		child.queue_free()

	var slot_scene := _get_inventory_slot_scene()
	var section_scene := _get_category_section_scene()
	if slot_scene == null or section_scene == null:
		return

	var buckets := _bucket_inventory()

	for category_id in ItemCategory.ORDER:
		var entries: Array = buckets.get(category_id, [])
		if entries.is_empty():
			continue  # a section with nothing in it is just noise

		var section: InventoryCategorySection = section_scene.instantiate()
		category_container.add_child(section)
		section.setup(category_id, _category_expanded.get(category_id, true))
		section.expanded_changed.connect(_on_section_expanded_changed)

		for entry in entries:
			var row: InventoryItemSlot = slot_scene.instantiate()
			section.add_row(row)
			row.setup(entry.item, entry.amount, _is_equipped(entry.item))
			row.slot_clicked.connect(_on_slot_clicked)
			row.slot_activated.connect(_on_slot_activated)

	_refresh_currency()
	_update_equipment_summary()
	_restore_selection()

	# Restoring the scroll has to wait for the containers to lay out, or the
	# scrollbar's max is still zero and the assignment clamps to nothing.
	await get_tree().process_frame
	if is_instance_valid(item_scroll):
		item_scroll.scroll_vertical = scroll_before


## Groups the inventory into display sections, sorted by name within each.
## Pickup order is meaningless to the player.
func _bucket_inventory() -> Dictionary:
	var buckets: Dictionary = {}

	for slot in GameState.player_inventory:
		var item = slot.item
		if item == null:
			continue
		# hidden_from_inventory lives on the base InventoryItem, so the check
		# must not be gated behind EquipableItem or hidden quest and key items
		# still show up. barter_screen.gd already gets this right.
		if item.hidden_from_inventory:
			continue

		var category_id := ItemCategory.classify(item)
		if not buckets.has(category_id):
			buckets[category_id] = []
		buckets[category_id].append(slot)

	for category_id in buckets:
		buckets[category_id].sort_custom(func(a, b) -> bool:
			return a.item.name.naturalnocasecmp_to(b.item.name) < 0
		)

	return buckets


func _on_section_expanded_changed(category_id: String, expanded: bool) -> void:
	_category_expanded[category_id] = expanded


## Every row currently on screen, across all sections.
func _all_rows() -> Array[InventoryItemSlot]:
	var rows: Array[InventoryItemSlot] = []
	for section in category_container.get_children():
		if section is InventoryCategorySection:
			for row in section.get_rows():
				if row is InventoryItemSlot:
					rows.append(row)
	return rows


func _is_equipped(item: InventoryItem) -> bool:
	if not item is EquipableItem:
		return false
	var equip_item := item as EquipableItem
	return (
		equip_item == GameState.equipped_weapon
		or equip_item == GameState.equipped_armor
		or equip_item == GameState.equipped_offhand
		or equip_item in GameState.equipped_trinkets
	)


func _on_inventory_changed(_action: String, _item) -> void:
	if visible:
		refresh()


func _on_state_restored() -> void:
	# Bulk state change (save loaded / new game). refresh() covers the currency
	# and equipment summary itself, so only the hidden case needs them directly.
	if visible:
		refresh()
	else:
		_refresh_currency()
		_update_equipment_summary()


# ──────────────────────────────────────────────────
# Equip / unequip

## A click selects the row so the inspector can show it. Equipping is the
## inspector button's job, or a double click via _on_slot_activated.
func _on_slot_clicked(slot: InventoryItemSlot) -> void:
	_select_row(slot)


## Selects one specific row.
##
## Highlighting is per row rather than per item on purpose: non-stackables are
## stored one entry per copy (gamestate.gd add_item), so owning two Long Sticks
## means two rows sharing a single InventoryItem resource. Matching on the item
## would light up both and read as a bug.
func _select_row(row: InventoryItemSlot) -> void:
	_selected_item = row.item if row != null else null
	for other in _all_rows():
		other.set_selected(other == row)

	if row == null:
		inspector.clear()
	else:
		inspector.show_item(row.item, row.is_equipped)


## Selects the first row holding this item. For callers that have an item rather
## than a row; the click path uses _select_row directly.
func _select_item(item: InventoryItem) -> void:
	if item == null:
		_select_row(null)
		return
	for row in _all_rows():
		if row.item == item:
			_select_row(row)
			return
	_select_row(null)


## The inspector's Equip button.
func _on_equip_requested(item: EquipableItem) -> void:
	_toggle_equip(item, false)


## The inspector's Unequip button.
func _on_unequip_requested(item: EquipableItem) -> void:
	_toggle_equip(item, true)


## Double click: the old one-click-equips behaviour, kept as a shortcut.
func _on_slot_activated(slot: InventoryItemSlot) -> void:
	_select_row(slot)
	_toggle_equip(slot.item, slot.is_equipped)


## Re-finds the selected row after the list is rebuilt.
##
## Matches by identity first. GameState._load_saved_item() uses load(), which
## returns the cached instance, so identity normally survives a save load, and
## the resource_path comparison is the fallback for when it does not.
func _restore_selection() -> void:
	if _selected_item == null:
		return

	var found: InventoryItemSlot = null
	for row in _all_rows():
		if row.item == _selected_item or (
				not _selected_item.resource_path.is_empty()
				and row.item.resource_path == _selected_item.resource_path):
			found = row
			break

	if found == null:
		# Sold, consumed, or wiped by a new game.
		_selected_item = null
		inspector.clear()
		return

	# Non-stackables append one entry per copy (gamestate.gd add_item), so two
	# Rusty Pipes are two rows sharing one resource and this picks the first.
	# Exact-occurrence tracking is not worth it until duplicate gear is common.
	_selected_item = found.item
	found.set_selected(true)
	inspector.show_item(found.item, found.is_equipped)


func _toggle_equip(item: InventoryItem, currently_equipped: bool) -> void:
	if not item is EquipableItem:
		return

	var equip_item := item as EquipableItem

	if currently_equipped:
		match equip_item.equip_type:
			"weapon":
				GameState.unequip_weapon()
			"armor":
				GameState.unequip_armor()
			"offhand":
				GameState.unequip_offhand()
			"trinket":
				GameState.unequip_trinket(equip_item)
	else:
		# GameState handles replacing whatever occupied the slot.
		match equip_item.equip_type:
			"weapon":
				GameState.equip_weapon(equip_item)
			"armor":
				GameState.equip_armor(equip_item)
			"offhand":
				GameState.equip_offhand(equip_item)
			"trinket":
				GameState.equip_trinket(equip_item)

	# No refresh() here. Every equip and unequip path emits fallback_equipped,
	# which lands in _on_equipment_changed and updates the rows in place.


## Any equipment slot changed. Driven by GameState.fallback_equipped, which
## every equip and unequip path emits.
##
## The set of owned items did not change, so the rows are updated in place
## rather than rebuilt. Rebuilding here would throw away the selection, the
## scroll position and the hover state on every single equip.
func _on_equipment_changed() -> void:
	_update_equipment_summary()
	for row in _all_rows():
		row.set_equipped(_is_equipped(row.item))
	# Re-render so the button flips between Equip and Unequip.
	if _selected_item != null:
		inspector.show_item(_selected_item, _is_equipped(_selected_item))


## Labels only. Cheap enough to run whether or not the screen is showing.
func _update_equipment_summary() -> void:
	current_weapon_label.text = "Weapon: " + (GameState.equipped_weapon.name if GameState.equipped_weapon != null else "None")
	current_armor_label.text = "Armor: " + (GameState.equipped_armor.name if GameState.equipped_armor != null else "None")
	current_offhand_label.text = "Offhand: " + (GameState.equipped_offhand.name if GameState.equipped_offhand != null else "None")

	var trinket_names: Array[String] = []
	for trinket in GameState.equipped_trinkets:
		trinket_names.append(trinket.name)
	current_trinkets_label.text = "Trinkets: " + (", ".join(trinket_names) if trinket_names else "None")

	# The grid is the expensive half, so defer it until the player can see it.
	_tile_grid_dirty = true
	if visible:
		_update_tile_grid()


# ──────────────────────────────────────────────────
# Currency

## Öre is the everyday currency and always shows. Crowns and drots are rare
## enough that a permanent "0" next to them is just clutter, so they appear only
## once the player actually has some.
func _refresh_currency() -> void:
	current_ore_label.text = "%s %d" % [GameState.ORE_SYMBOL, GameState.player_ore]
	current_crowns_label.text = "%s %d" % [GameState.CROWN_SYMBOL, GameState.player_crowns]
	current_drots_label.text = "%s %d" % [GameState.DROT_SYMBOL, GameState.player_drots]
	current_crowns_label.visible = GameState.player_crowns > 0
	current_drots_label.visible = GameState.player_drots > 0


func _on_money_changed(currency: String, new_amount: int) -> void:
	match currency:
		"ore":
			current_ore_label.text = "%s %d" % [GameState.ORE_SYMBOL, new_amount]
		"crowns":
			current_crowns_label.text = "%s %d" % [GameState.CROWN_SYMBOL, new_amount]
			current_crowns_label.visible = new_amount > 0
		"drots":
			current_drots_label.text = "%s %d" % [GameState.DROT_SYMBOL, new_amount]
			current_drots_label.visible = new_amount > 0


# ──────────────────────────────────────────────────
# Tile pile preview

func _update_tile_grid() -> void:
	_tile_grid_dirty = false
	tile_pile_panel.refresh()
