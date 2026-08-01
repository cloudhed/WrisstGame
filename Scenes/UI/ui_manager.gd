extends Control

## Host for the persistent UI layer: screen routing and input, the notification
## toasts, and the barter and logbook screens.
##
## The inventory screen's own contents are owned by inventory_screen.gd on the
## InventoryScreen node. This script only opens and closes it.

@onready var inv_screen: InventoryScreen = $UIContainer/InventoryScreen
@onready var logbook_screen: LogbookScreen = %LogbookScreen

#-NOTIFICATION POPUP-#
@onready var popup_panel: Panel = %NotificationPopup
@onready var popup_label: Label = %NotificationLabel
@onready var hide_timer: Timer = %NotificationHideTimer

const BARTER_SCREEN_PATH := "res://Scenes/UI/Barter/barter_screen.tscn"

var _barter_screen_scene: PackedScene = null
var barter_screen: BarterScreen = null


func _ready():
	popup_panel.visible = false

	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.money_changed.connect(_on_money_changed)
	GameState.logbook_updated.connect(_on_logbook_updated)

	Events.barter_requested.connect(_on_barter_requested)

	hide_timer.timeout.connect(_on_hide_timer_timeout)
	logbook_screen.logbook_closed.connect(_on_logbook_closed)
	inv_screen.inventory_closed.connect(_enable_hotspots)

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
# Inventory

func _toggle_inventory():
	if inv_screen.visible:
		inv_screen.close()
	else:
		inv_screen.open()
		_disable_hotspots()


func _on_inventory_changed(action: String, item):
	if item == null:
		return  # bulk change (save loaded / new game) — nothing to toast
	if action == "add":
		notify("'%s' added" % item.name)
	else:
		notify("'%s' removed" % item.name)


# ──────────────────────────────────────────────────
# World hotspots

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
	notify("%s: %d" % [currency.capitalize(), new_amount])


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
