extends Node

const PLAYER_STATISTICS_SCRIPT := preload("res://Scripts/autoload/player_statistics.gd")

signal money_changed(currency: String, new_amount: int)
signal reputation_changed(npc_id: String, new_value: int)
signal inventory_changed(action: String, item)
signal fallback_equipped
signal combat_debug_settings_changed

@export var grant_debug_starting_items: bool = true
@export var debug_immediate_discard_reshuffle: bool = false

# ─────────────────────────────────────────────────────────────
# Player identity
var player_name: String = "MilkshakeMan"
var player_gender: String = "male" # "female" or "male",
#var player_body_type: String = "curvy" # or "flat", "androgynous", etc.
#var player_pronouns: Dictionary = {
#	"they": "she",
#	"them": "her",
#	"their": "her"
#}

# DEFAULT FALLBACK NAKED&CONFUSED
const FALLBACK_ARMOR_PATH := "res://Resources/Items/Equipment/Armor/naked_armor.tres"
const FALLBACK_WEAPON_PATH := "res://Resources/Items/Equipment/Weapons/long_stick_weapon.tres" #default is unarmed_weapon.tres

var FALLBACK_ARMOR: EquipableItem = null
var FALLBACK_WEAPON: EquipableItem = null
# FAILS FOR SOME REASON, CONST BEING PISSY ABOUT MY ARMOR RESOURCE NOT BEING A EQUIPABLEITEM EVEN THOUGH IT IS const FALLBACK_ARMOR := preload("res://Resources/Items/Equipment/Armor/fallback_naked_armor.res")
# const FALLBACK_WEAPON := preload("res://Resources/Items/Equipment/Weapons/fallback_unarmed_weapon.res")


# Player stats and resources
var player_stats: CharacterStats = null
var player_statistics: Resource = null
var player_ore: int = 0
var player_crowns: int = 0
var player_drots: int = 0
var player_inventory: Array = []

##Is this a place where we should check for deck parts? Like the starter deck? And then Weapon/Armor and their influence on the deck?##

# Flags for quests, dialogs, and events
var quest_flags: Dictionary = {}
var dialog_flags: Dictionary = {}
var event_flags: Dictionary = {}
var knowledge_flags: Dictionary = {}
var sex_flags: Dictionary = {}
var temp_flags: Dictionary = {}

# NPC relationship points
var npc_reputation: Dictionary = {}

# Returning to stuff
var last_scene_id: String = ""
var return_to_scene: PackedScene = null
var pending_dialog_scene_data: DialogSceneResource = null


# ─────────────────────────────────────────────────────────────
# Debugging in the ready() func!
func _ready():
	_ensure_fallback_items_loaded()

	if player_statistics == null:
		player_statistics = PLAYER_STATISTICS_SCRIPT.new()
	
	if player_stats == null:
		player_stats = load("res://Characters/Player/player.tres") as CharacterStats
		if player_stats == null:
			push_error("❌ Failed to load fallback player_stats from player.tres!")
		else:
			print("✅ player_stats loaded from player.tres")

	if grant_debug_starting_items:
		var debug_armor: EquipableItem = load("res://Resources/Items/Equipment/Armor/debugger_armor.tres")
		var debug_weapon: EquipableItem = load("res://Resources/Items/Equipment/Weapons/debugger_weapon.tres")
		var debug_trinket: EquipableItem = load("res://Resources/Items/Equipment/Trinkets/debugger_trinket.tres")
		var debug_longstick: EquipableItem = load("res://Resources/Items/Equipment/Weapons/long_stick_weapon.tres")
		add_item(debug_armor)
		add_item(debug_weapon)
		add_item(debug_longstick)
		add_item(debug_trinket)
	
	check_and_equip_fallback()


func _ensure_fallback_items_loaded() -> void:
	if FALLBACK_ARMOR == null:
		FALLBACK_ARMOR = load(FALLBACK_ARMOR_PATH) as EquipableItem
		if FALLBACK_ARMOR == null:
			push_error("❌ Failed to load fallback armor: " + FALLBACK_ARMOR_PATH)

	if FALLBACK_WEAPON == null:
		FALLBACK_WEAPON = load(FALLBACK_WEAPON_PATH) as EquipableItem
		if FALLBACK_WEAPON == null:
			push_error("❌ Failed to load fallback weapon: " + FALLBACK_WEAPON_PATH)


# ─────────────────────────────────────────────────────────────
# Here be the money-stuff!
func add_ore(amount: int) -> void:
	player_ore += amount
	print("💰 Öre +%d → Total: %d" % [amount, player_ore])
	emit_signal("money_changed", "ore", player_ore)

func remove_ore(amount: int) -> bool:
	if amount > player_ore:
		print("❌ Tried to remove %d öre, but only %d available" % [amount, player_ore])
		return false
	player_ore -= amount
	print("💸 Öre -%d → Total: %d" % [amount, player_ore])
	emit_signal("money_changed", "ore", player_ore)
	return true


func add_crowns(amount: int) -> void:
	player_crowns += amount
	print("💰 Crowns +%d → Total: %d" % [amount, player_crowns])
	emit_signal("money_changed", "crowns", player_crowns)

func remove_crowns(amount: int) -> bool:
	if amount > player_crowns:
		print("❌ Tried to remove %d crowns, but only %d available" % [amount, player_crowns])
		return false
	player_crowns -= amount
	print("💸 Crowns -%d → Total: %d" % [amount, player_crowns])
	emit_signal("money_changed", "crowns", player_crowns)
	return true


func add_drots(amount: int) -> void:
	player_drots += amount
	print("💰 Drots +%d → Total: %d" % [amount, player_drots])
	emit_signal("money_changed", "drots", player_drots)

func remove_drots(amount: int) -> bool:
	if amount > player_drots:
		print("❌ Tried to remove %d drots, but only %d available" % [amount, player_drots])
		return false
	player_drots -= amount
	print("💸 Drots -%d → Total: %d" % [amount, player_drots])
	emit_signal("money_changed", "drots", player_drots)
	return true


# ─────────────────────────────────────────────────────────────
# Inventory management
func add_item(item: InventoryItem, amount: int = 1) -> void:
	if item.is_stackable:
		for slot in player_inventory:
			if slot.item == item:
				slot.amount += amount
				print("➕ Stacked item:", item.name, "New amount:", slot.amount)
				emit_signal("inventory_changed", "add", item)
				return
		# No existing stack, create new
		player_inventory.append({
			"item": item,
			"amount": amount
		})
		print("📦 New stack created:", item.name, "x", amount)
	else:
		# Non-stackable items
		for i in range(amount):
			player_inventory.append({
				"item": item,
				"amount": 1
			})
		print("📦 Added non-stackable item:", item.name, "x", amount)

	emit_signal("inventory_changed", "add", item)

func remove_item(item: InventoryItem, amount: int = 1) -> bool:
	for slot in player_inventory:
		if slot.item == item:
			if slot.amount > amount:
				slot.amount -= amount
				print("➖ Reduced stack of", item.name, "to", slot.amount)
			elif slot.amount == amount:
				player_inventory.erase(slot)
				print("🗑️ Removed entire stack of", item.name)
			else:
				print("❌ Tried to remove more than available!")
				return false
			emit_signal("inventory_changed", "remove", item)
			return true
	print("❌ Tried to remove item not found:", item.name)
	return false

func has_item(item: InventoryItem) -> bool:
	for slot in player_inventory:
		if slot.item == item and slot.amount > 0:
			return true
	return false


# ─────────────────────────────────────────────────────────────
# Equipable gear

var equipped_weapon: EquipableItem = null
var equipped_armor: EquipableItem = null
var equipped_trinkets: Array[EquipableItem] = []

func equip_weapon(item: EquipableItem) -> void:
	if item.equip_type != "weapon":
		push_error("Trying to equip non-weapon as weapon.")
		return
	
	# Unequip current weapon if there is one
	if equipped_weapon and equipped_weapon != item:
		print("🗡️ Unequipping previous weapon:", equipped_weapon.name)
		# You can emit a signal here if you want
	
	equipped_weapon = item
	print("🧪 Equipped weapon:", item.name)
	fallback_equipped.emit()  # Update UI

func equip_armor(item: EquipableItem) -> void:
	if item.equip_type != "armor":
		push_error("Trying to equip non-armor as armor.")
		return
	
	# Unequip current armor if there is one
	if equipped_armor and equipped_armor != item:
		print("🛡️ Unequipping previous armor:", equipped_armor.name)
	
	equipped_armor = item
	print("🥷 Equipped armor:", item.name)
	fallback_equipped.emit()

func equip_trinket(item: EquipableItem) -> void:
	if item.equip_type != "trinket":
		push_error("Trying to equip non-trinket as trinket.")
		return
	
	# No duplicates allowed
	if equipped_trinkets.has(item):
		print("⚠️ Trinket already equipped:", item.name)
		return
	
	equipped_trinkets.append(item)
	print("🔮 Equipped trinket:", item.name)
	fallback_equipped.emit()

func unequip_weapon() -> void:
	equipped_weapon = null
	check_and_equip_fallback()

func unequip_armor() -> void:
	equipped_armor = null
	check_and_equip_fallback()

func unequip_trinket(item: EquipableItem) -> void:
	equipped_trinkets.erase(item)


func check_and_equip_fallback() -> void:
	_ensure_fallback_items_loaded()

	if equipped_weapon == null:
		equipped_weapon = FALLBACK_WEAPON
		print("⚠️ No weapon equipped. Falling back to UNARMED.")
	if equipped_armor == null:
		equipped_armor = FALLBACK_ARMOR
		print("⚠️ No armor equipped. Falling back to NAKED.")

	fallback_equipped.emit()


# ─────────────────────────────────────────────────────────────
# NPC reputation management
func add_reputation(npc_id: String, amount: int) -> void:
	var old = npc_reputation.get(npc_id, 0)
	var nw = old + amount
	npc_reputation[npc_id] = nw
	print("Reputation increased by %d" % [nw])
	print("Or is it: Reputation increased by %d" % [amount])
	emit_signal("reputation_changed", npc_id, nw)

func remove_reputation(npc_id: String, amount: int) -> bool:
	var old = npc_reputation.get(npc_id, 0)
	if amount > old:
		return false
	var nw = old - amount
	npc_reputation[npc_id] = nw
	print("Reputation decreased by %d" % [nw])
	emit_signal("reputation_changed", npc_id, nw)
	return true

func get_reputation(npc_id: String) -> int:
	return npc_reputation.get(npc_id, 0)


# ─────────────────────────────────────────────────────────────
# Generic flag helpers (quests, dialogs, events)
func set_flag(flag_dict: Dictionary, key: String) -> void:
	flag_dict[key] = true

func clear_flag(flag_dict: Dictionary, key: String) -> void:
	flag_dict.erase(key)

func has_flag(flag_dict: Dictionary, key: String) -> bool:
	return flag_dict.has(key) and flag_dict[key] == true


func toggle_debug_immediate_discard_reshuffle() -> void:
	debug_immediate_discard_reshuffle = not debug_immediate_discard_reshuffle
	combat_debug_settings_changed.emit()


func get_debug_reshuffle_mode_label() -> String:
	return "Immediate discard reshuffle" if debug_immediate_discard_reshuffle else "Cycle deck before reshuffle"
