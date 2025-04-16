extends Control

# We assume GameState is your autoload singleton
@onready var inventory_screen: Panel       = $UIContainer/InventoryScreen

# Cache node paths for easier access:
@onready var inv_screen                    = $UIContainer/InventoryScreen
@onready var item_list                     = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/ItemListContainer/ItemList    # adjust if you used a different container
@onready var inventory_list: VBoxContainer = $UIContainer/InventoryScreen/HBoxContainer/VBoxContainer/Panel/MarginContainer/Panel/HBoxContainer/InventoryContainer/InventoryList
@onready var popup_panel                   = $UIContainer/NotificationPopup
@onready var popup_label                   = $UIContainer/NotificationPopup/Label
@onready var hide_timer: Timer             = $UIContainer/NotificationPopup/HideTimer


func _ready():
	print("▶️ UIManager is running in:", self.name)
	print("Popup panel:", popup_panel)
	print("HideTimer:", hide_timer)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.reputation_changed.connect(_on_reputation_changed)
	hide_timer.timeout.connect(_on_hide_timer_timeout)

	inv_screen.focus_mode = Control.FOCUS_ALL
	inv_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	popup_panel.focus_mode = Control.FOCUS_ALL
	popup_panel.mouse_filter = Control.MOUSE_FILTER_STOP


func _unhandled_input(ev):
	# Toggle inventory on “I” press (make sure you set ui_inventory in InputMap)
	if ev.is_action_pressed("ui_inventory"):
		_toggle_inventory()

#func _input(event: InputEvent) -> void:
	# If the inventory (or any blocking UI) is visible, consume accept + mouse clicks
#	if inv_screen.visible:
		# catch left-click
#		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			# eat the click so dialog doesn't advance
#			get_tree().set_input_as_handled()
#			return
		# catch “ui_accept” (Enter, Space, etc)
#		if event.is_action_pressed("ui_accept"):
#			get_tree().set_input_as_handled()
#			return

# ← Put this **directly after** your _unhandled_input (or anywhere in the class body):
func _gui_input(event: InputEvent) -> void:
	if inv_screen.visible and (event is InputEventMouseButton or event.is_action_pressed("ui_accept")):
		event.accept()


func is_ui_open() -> bool:
	return inv_screen.visible or popup_panel.visible
# ──────────────────────────────────────────────────
# Inventory methods

func _toggle_inventory():
	inv_screen.visible = not inv_screen.visible
	if inv_screen.visible:
		_refresh_inventory()


func _refresh_inventory():
	item_list.clear()
	# Add each item in GameState.player_inventory
	for item in GameState.player_inventory:
		item_list.add_item(str(item))  # or item.name if it’s an object


# Called whenever add_item or remove_item happens
func _on_inventory_changed(action: String, item):
	# If inventory is open, immediately refresh
	if inv_screen.visible:
		_refresh_inventory()
	# Also pop up a notification:
	if action == "add":
		notify("Got “%s”!" % item)
	else:
		notify("Lost “%s”!" % item)


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

func _on_reputation_changed(npc_id: String, new_value: int) -> void:
	# Show rep with the NPC by name
	var pretty_name = npc_id.capitalize()
	var msg = "Reputation with %s: %d" % [pretty_name, new_value]
	notify(msg)
