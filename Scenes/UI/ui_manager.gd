extends Control

# Cache node paths for easier access:
@onready var inv_screen: Panel = $UIContainer/InventoryScreen
#LEFT STIDE
@onready var item_list: ItemList = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/ItemListContainer/MarginContainer/ItemList
#RIGHT STIDE
@onready var inventory_list: VBoxContainer = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/InventoryContainer/InventoryList

#-CURRENCY-#
@onready var current_ore_label: Label = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/InventoryContainer/InventoryList/CurrencyHbox/CurrentOreLabel
@onready var current_crowns: Label = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/InventoryContainer/InventoryList/CurrencyHbox/CurrentCrownsLabel
@onready var current_drots: Label = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/InventoryContainer/InventoryList/CurrencyHbox/CurrentDrotsLabel

#-WEAPON, ARMOR, TRINKETS-#
@onready var current_weapon_label: Label = %EquippedWeaponLabel
@onready var current_armor_label: Label = %EquippedArmorLabel
@onready var current_trinkets_label: Label = %EquippedTrinketsLabel


#-TILE PILE-#
@onready var current_tiles_amount: Label = %CurrentTilesLabel
@onready var pile_power_label: Label = %PilePowerLabel

@onready var tile_grid: GridContainer = %TileGrid


#-NOTIFICATION POPUP-#
@onready var popup_panel: Panel = %NotificationPopup
@onready var popup_label: Label = %NotificationLabel
@onready var hide_timer: Timer = %NotificationHideTimer


func _ready():
	inv_screen.visible = false
	popup_panel.visible = false
	
	print("🎯 Equipped weapon label:", current_weapon_label)
	
	print("▶️ UIManager is running in:", self.name)
	print("Popup panel:", popup_panel)
	print("HideTimer:", hide_timer)

	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	GameState.fallback_equipped.connect(_update_equipped_labels)
	print("✅ Connected fallback_equipped to _update_equipped_labels")
	
	hide_timer.timeout.connect(_on_hide_timer_timeout)

	item_list.item_clicked.connect(_on_item_clicked)
	
	_update_tile_grid()
	

	inv_screen.focus_mode = Control.FOCUS_ALL
	inv_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_panel.focus_mode = Control.FOCUS_ALL
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	print("🖱️ Item clicked at index:", index)
	if index < 0 or index >= GameState.player_inventory.size():
		return

	var slot = GameState.player_inventory[index]
	var item = slot.item

	if not item or not item is EquipableItem:
		return

	var is_selected: bool = item_list.is_selected(index)
	_on_item_toggled(index, is_selected)


func _unhandled_input(ev):
	# Toggle inventory on “I” press (make sure you set ui_inventory in InputMap)
	if ev.is_action_pressed("ui_inventory"):
		_toggle_inventory()


# ← Put this **directly after** your _unhandled_input (or anywhere in the class body):
func _gui_input(event: InputEvent) -> void:
	if inv_screen.visible and (event is InputEventMouseButton or event.is_action_pressed("ui_accept")):
		event.accept()


func is_ui_open() -> bool:
	return inv_screen.visible #or popup_panel.visible
# ──────────────────────────────────────────────────
# Inventory methods

func _toggle_inventory():
	inv_screen.visible = not inv_screen.visible
	if inv_screen.visible:
		_refresh_inventory()


func _refresh_inventory():
	item_list.clear()

	for slot in GameState.player_inventory:
		var item = slot.item
		var amount = slot.amount

		if item is EquipableItem and item.hidden_from_inventory:
			continue

		var display_name = item.name
		if item.is_stackable and amount > 1:
			display_name += " x%d" % amount  # Show quantity if stackable

		item_list.add_item(display_name, item.icon)
		
		var index := item_list.item_count - 1
		if item == GameState.equipped_weapon or item == GameState.equipped_armor or item in GameState.equipped_trinkets:
			item_list.select(index)


	# Update currency labels
	current_ore_label.text = "Öre: %d" % GameState.player_ore
	current_crowns.text = "Crowns: %d" % GameState.player_crowns
	current_drots.text = "Drots: %d" % GameState.player_drots

	_update_equipped_labels()  # keep equipped panel in sync


# Called whenever add_item or remove_item happens
func _on_inventory_changed(action: String, item):
	# If inventory is open, immediately refresh
	if inv_screen.visible:
		_refresh_inventory()
	# Also pop up a notification:
	if action == "add":
		notify("Got “%s”!" % item.name)
	else:
		notify("Lost “%s”!" % item.name)

# ──────────────────────────────────────────────────
# ITEM AND EQUIPMENT #
func _on_item_toggled(index: int, checked: bool) -> void:
	var slot = GameState.player_inventory[index]
	var item = slot.item

	if not item or not item is EquipableItem:
		return
	
	match item.equip_type:
		"weapon":
			if checked:
				# Unequip old weapon and uncheck its checkbox
				if GameState.equipped_weapon and GameState.equipped_weapon != item:
					_uncheck_item(GameState.equipped_weapon)
				GameState.equip_weapon(item)
			elif GameState.equipped_weapon == item:
				GameState.unequip_weapon()

		"armor":
			if checked:
				if GameState.equipped_armor and GameState.equipped_armor != item:
					_uncheck_item(GameState.equipped_armor)
				GameState.equip_armor(item)
			elif GameState.equipped_armor == item:
				GameState.unequip_armor()

		"trinket":
			if checked:
				GameState.equip_trinket(item)
			else:
				GameState.unequip_trinket(item)

	print("🎯 Equipped weapon now:", GameState.equipped_weapon)
	_update_equipped_labels()


func _uncheck_item(item: EquipableItem) -> void:
	for i in GameState.player_inventory.size():
		var slot = GameState.player_inventory[i]
		if slot.item == item:
			item_list.deselect(i)
			break


func _update_equipped_labels() -> void:
	#print("🔄 [_update_equipped_labels()] called")

	current_weapon_label.text = "Weapon: " + (GameState.equipped_weapon.name if GameState.equipped_weapon != null else "None")
	current_armor_label.text = "Armor: " + (GameState.equipped_armor.name if GameState.equipped_armor != null else "None")

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

	# Armor tiles
	if GameState.equipped_armor and GameState.equipped_armor.tile_bundle:
		tile_pile += GameState.equipped_armor.tile_bundle.tiles

	# Trinket tiles
	for trinket in GameState.equipped_trinkets:
		if trinket.tile_bundle:
			tile_pile += trinket.tile_bundle.tiles

	# Sort by effect_amount (descending)
	tile_pile.sort_custom(func(a: Tile, b: Tile) -> bool:
		return a.effect_amount > b.effect_amount
	)

	# Add to grid
	for tile in tile_pile:
		var card = preload("res://Scenes/TileUI/tile_grid_card.tscn").instantiate()
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
				total_value += 0  # Optional: skip BUFF/DEBUFF/OTHER types

	if tiles.is_empty():
		return 0.0

	var average_value := total_value / tiles.size()
	var final_score := average_value * 10.0
	return round(final_score * 10) / 10.0  # Round to 1 decimal


# ──────────────────────────────────────────────────
# Notification methods

func notify(text: String, duration: float = 2.0):
	popup_label.text = text
	popup_panel.visible = true
	hide_timer.wait_time = duration
	hide_timer.start()

func _on_hide_timer_timeout():
	popup_panel.visible = false


# CONNECT THESE IN _ready():
# GameState.connect("money_changed",        self, "_on_money_changed")
# GameState.connect("reputation_changed",   self, "_on_reputation_changed")

func _on_money_changed(currency: String, new_amount: int) -> void:
	# Capitalize the currency name and show the new total
	var pretty = "%s: %d" % [currency.capitalize(), new_amount]
	notify(pretty)

	match currency:
		"ore":
			current_ore_label.text = "Ore: %d" % new_amount
		"crowns":
			current_crowns.text = "Crowns: %d" % new_amount
		"drots":
			current_drots.text = "Drots: %d" % new_amount

func _on_reputation_changed(npc_id: String, new_value: int) -> void:
	# Show rep with the NPC by name
	var pretty_name = npc_id.capitalize()
	var msg = "Reputation with %s: %d" % [pretty_name, new_value]
	notify(msg)
