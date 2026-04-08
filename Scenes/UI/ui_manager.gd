extends Control

@onready var inv_screen: Panel = $UIContainer/InventoryScreen
@onready var logbook_screen: LogbookScreen = %LogbookScreen

#-ITEM CONTAINER-#
@onready var item_container: VBoxContainer = %ItemContainer

#-CURRENCY-#
@onready var current_ore_label: Label = %CurrentOreLabel
@onready var current_crowns: Label = %CurrentCrownsLabel
@onready var current_drots: Label = %CurrentDrotsLabel

#-WEAPON, ARMOR, OFFHAND, TRINKETS-#
@onready var current_weapon_label: Label = %EquippedWeaponLabel
@onready var current_armor_label: Label = %EquippedArmorLabel
@onready var current_offhand_label: Label = %EquippedOffhandLabel
@onready var current_trinkets_label: Label = %EquippedTrinketsLabel

#-TILE PILE-#
@onready var current_tiles_amount: Label = %CurrentTilesLabel
@onready var pile_power_label: Label = %PilePowerLabel
@onready var tile_grid: GridContainer = %TileGrid

#-NOTIFICATION POPUP-#
@onready var popup_panel: Panel = %NotificationPopup
@onready var popup_label: Label = %NotificationLabel
@onready var hide_timer: Timer = %NotificationHideTimer

const TILE_GRID_CARD_SCENE_PATH := "res://Scenes/TileUI/tile_grid_card.tscn"
const BARTER_SCREEN_PATH := "res://Scenes/UI/Barter/barter_screen.tscn"
const INVENTORY_SLOT_SCENE_PATH := "res://Scenes/UI/inventory_item_slot.tscn"

var _tile_grid_card_scene: PackedScene = null
var _barter_screen_scene: PackedScene = null
var _inventory_slot_scene: PackedScene = null
var barter_screen: BarterScreen = null


func _get_tile_grid_card_scene() -> PackedScene:
	if _tile_grid_card_scene == null:
		_tile_grid_card_scene = load(TILE_GRID_CARD_SCENE_PATH) as PackedScene
		if _tile_grid_card_scene == null:
			push_error("❌ Failed to load tile grid card scene: " + TILE_GRID_CARD_SCENE_PATH)
	return _tile_grid_card_scene


func _get_inventory_slot_scene() -> PackedScene:
	if _inventory_slot_scene == null:
		_inventory_slot_scene = load(INVENTORY_SLOT_SCENE_PATH) as PackedScene
		if _inventory_slot_scene == null:
			push_error("❌ Failed to load inventory slot scene: " + INVENTORY_SLOT_SCENE_PATH)
	return _inventory_slot_scene


func _ready():
	inv_screen.visible = false
	popup_panel.visible = false

	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.fallback_equipped.connect(_update_equipped_labels)
	GameState.logbook_updated.connect(_on_logbook_updated)

	Events.barter_requested.connect(_on_barter_requested)

	hide_timer.timeout.connect(_on_hide_timer_timeout)
	logbook_screen.logbook_closed.connect(_on_logbook_closed)

	_update_tile_grid()

	inv_screen.focus_mode = Control.FOCUS_ALL
	inv_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_panel.focus_mode = Control.FOCUS_ALL
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _unhandled_input(ev):
	if ev.is_action_pressed("inventory"):
		# Block inventory while barter or logbook is open
		if barter_screen != null and barter_screen.visible:
			return
		if logbook_screen.visible:
			return
		_toggle_inventory()
	elif ev.is_action_pressed("logbook"):
		# Block logbook while barter or inventory is open
		if barter_screen != null and barter_screen.visible:
			return
		if inv_screen.visible:
			return
		_toggle_logbook()


func _gui_input(event: InputEvent) -> void:
	if inv_screen.visible and (event is InputEventMouseButton or event.is_action_pressed("confirm")):
		event.accept()


func is_ui_open() -> bool:
	return inv_screen.visible or logbook_screen.visible or (barter_screen != null and barter_screen.visible)


# ──────────────────────────────────────────────────
# Inventory methods

func _toggle_inventory():
	inv_screen.visible = not inv_screen.visible
	if inv_screen.visible:
		_refresh_inventory()
		_disable_hotspots()
	else:
		_enable_hotspots()


func _refresh_inventory():
	# Clear existing item slots
	for child in item_container.get_children():
		child.queue_free()

	var slot_scene := _get_inventory_slot_scene()
	if slot_scene == null:
		return

	for slot in GameState.player_inventory:
		var item = slot.item
		var amount = slot.amount

		if item is EquipableItem and item.hidden_from_inventory:
			continue

		var is_equipped := false
		if item is EquipableItem:
			var equip_item := item as EquipableItem
			is_equipped = (
				equip_item == GameState.equipped_weapon
				or equip_item == GameState.equipped_armor
				or equip_item == GameState.equipped_offhand
				or equip_item in GameState.equipped_trinkets
			)

		var item_slot := slot_scene.instantiate()
		item_slot.setup(item, amount, is_equipped)
		item_slot.slot_clicked.connect(_on_slot_clicked)
		item_container.add_child(item_slot)

	# Update currency labels
	current_ore_label.text = "Öre: %d %s" % [GameState.player_ore, GameState.ORE_SYMBOL]
	current_crowns.text = "Crowns: %d %s" % [GameState.player_crowns, GameState.CROWN_SYMBOL]
	current_drots.text = "Drots: %d %s" % [GameState.player_drots, GameState.DROT_SYMBOL]

	_update_equipped_labels()


func _on_inventory_changed(action: String, item):
	if inv_screen.visible:
		_refresh_inventory()
	if action == "add":
		notify("'%s' added" % item.name)
	else:
		notify("'%s' removed" % item.name)


# ──────────────────────────────────────────────────
# ITEM AND EQUIPMENT

func _on_slot_clicked(slot: InventoryItemSlot) -> void:
	var item = slot.item
	if not item is EquipableItem:
		return

	var equip_item := item as EquipableItem

	if slot.is_equipped:
		# Unequip
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
		# Equip (GameState handles replacing the old item)
		match equip_item.equip_type:
			"weapon":
				GameState.equip_weapon(equip_item)
			"armor":
				GameState.equip_armor(equip_item)
			"offhand":
				GameState.equip_offhand(equip_item)
			"trinket":
				GameState.equip_trinket(equip_item)

	_update_equipped_labels()
	_refresh_inventory()


func _update_equipped_labels() -> void:
	current_weapon_label.text = "Weapon: " + (GameState.equipped_weapon.name if GameState.equipped_weapon != null else "None")
	current_armor_label.text = "Armor: " + (GameState.equipped_armor.name if GameState.equipped_armor != null else "None")
	current_offhand_label.text = "Offhand: " + (GameState.equipped_offhand.name if GameState.equipped_offhand != null else "None")

	var trinket_names: Array[String] = []
	for trinket in GameState.equipped_trinkets:
		trinket_names.append(trinket.name)

	current_trinkets_label.text = "Trinkets: " + (", ".join(trinket_names) if trinket_names else "None")

	_update_tile_grid()


func _update_tile_grid():
	# Clear the grid first
	for child in tile_grid.get_children():
		tile_grid.remove_child(child)
		child.queue_free()

	var tile_pile: Array[Tile] = []

	# Weapon tiles
	if GameState.equipped_weapon and GameState.equipped_weapon.tile_bundle:
		tile_pile += GameState.equipped_weapon.tile_bundle.tiles

	# Offhand tiles
	if GameState.equipped_offhand and GameState.equipped_offhand.tile_bundle:
		tile_pile += GameState.equipped_offhand.tile_bundle.tiles

	# Trinket tiles
	for trinket in GameState.equipped_trinkets:
		if trinket.tile_bundle:
			tile_pile += trinket.tile_bundle.tiles

	# Sort by effect_amount (descending)
	tile_pile.sort_custom(func(a: Tile, b: Tile) -> bool:
		return a.effect_amount > b.effect_amount
	)

	# Add to grid
	var card_scene := _get_tile_grid_card_scene()
	if card_scene == null:
		return

	for tile in tile_pile:
		var card = card_scene.instantiate()
		card.tile = tile
		tile_grid.add_child(card)

		current_tiles_amount.text = "Tiles: %d" % tile_pile.size()

	var power = _calculate_deck_power(tile_pile)
	pile_power_label.text = "Pile Power: %.1f" % power


func _calculate_deck_power(tiles: Array[Tile]) -> float:
	var total_value: float = 0.0
	for tile in tiles:
		match tile.type:
			Tile.Type.ATTACK, Tile.Type.DEFEND:
				total_value += tile.effect_amount
			Tile.Type.POWER:
				total_value += 86
			Tile.Type.FAIL:
				total_value -= 0.5
			_:
				total_value += 0

	if tiles.is_empty():
		return 0.0

	var average_value := total_value / tiles.size()
	var final_score := average_value * 10.0
	return round(final_score * 10) / 10.0


func _disable_hotspots():
	for node in get_tree().get_nodes_in_group("hotspots"):
		if node is Area2D:
			node.input_pickable = false

func _enable_hotspots():
	for node in get_tree().get_nodes_in_group("hotspots"):
		if node is Area2D:
			node.input_pickable = true


# ──────────────────────────────────────────────────
# Notification methods

func notify(text: String, duration: float = 2.0):
	popup_label.text = text
	popup_panel.visible = true
	hide_timer.wait_time = duration
	hide_timer.start()

func _on_hide_timer_timeout():
	popup_panel.visible = false


func _on_money_changed(currency: String, new_amount: int) -> void:
	var pretty = "%s: %d" % [currency.capitalize(), new_amount]
	notify(pretty)

	match currency:
		"ore":
			current_ore_label.text = "Öre: %d %s" % [new_amount, GameState.ORE_SYMBOL]
		"crowns":
			current_crowns.text = "Crowns: %d %s" % [new_amount, GameState.CROWN_SYMBOL]
		"drots":
			current_drots.text = "Drots: %d %s" % [new_amount, GameState.DROT_SYMBOL]

func _on_reputation_changed(npc_id: String, new_value: int) -> void:
	var pretty_name = npc_id.capitalize()
	var msg = "Reputation with %s: %d" % [pretty_name, new_value]
	notify(msg)


# ──────────────────────────────────────────────────
# Barter screen

func _on_barter_requested(shop: Resource) -> void:
	if barter_screen == null:
		if _barter_screen_scene == null:
			_barter_screen_scene = load(BARTER_SCREEN_PATH) as PackedScene
		barter_screen = _barter_screen_scene.instantiate()
		$UIContainer.add_child(barter_screen)
		barter_screen.barter_closed.connect(_on_barter_closed)

	barter_screen.open(shop)
	_disable_hotspots()


func _on_barter_closed() -> void:
	_enable_hotspots()
	Events.barter_closed.emit()


# ──────────────────────────────────────────────────
# Logbook methods

func _toggle_logbook() -> void:
	if logbook_screen.visible:
		logbook_screen.close()
	else:
		logbook_screen.open()
		_disable_hotspots()


func _on_logbook_closed() -> void:
	_enable_hotspots()


func _on_logbook_updated(_entry_id: String) -> void:
	if not logbook_screen.visible:
		notify("Logbook updated")
