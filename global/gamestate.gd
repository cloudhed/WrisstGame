extends Node

signal money_changed(currency: String, new_amount: int)
signal reputation_changed(npc_id: String, new_value: int)
signal inventory_changed(action: String, item)
signal fallback_equipped

# DEFAULT FALLBACK NAKED&CONFUSED
var FALLBACK_ARMOR: EquipableItem = load("res://Resources/Items/Equipment/Armor/naked_armor.tres")
var FALLBACK_WEAPON: EquipableItem = load("res://Resources/Items/Equipment/Weapons/unarmed_weapon.tres")
# FAILS FOR SOME REASON, CONST BEING PISSY ABOUT MY ARMOR RESOURCE NOT BEING A EQUIPABLEITEM EVEN THOUGH IT IS const FALLBACK_ARMOR := preload("res://Resources/Items/Equipment/Armor/fallback_naked_armor.res")
# const FALLBACK_WEAPON := preload("res://Resources/Items/Equipment/Weapons/fallback_unarmed_weapon.res")


# Player stats and resources
var player_stats: CharacterStats = null
var player_ore: int = 0
var player_crowns: int = 0
var player_drots: int = 0
var player_inventory: Array = []

##Is this a place where we should check for deck parts? Like the starter deck? And then Weapon/Armor and their influence on the deck?##

# Flags for quests, dialogs, and events
var quest_flags: Dictionary = {}
var dialog_flags: Dictionary = {}
var event_flags: Dictionary = {}

# NPC relationship points
var npc_reputation: Dictionary = {}


# ─────────────────────────────────────────────────────────────
# Debugging in the ready() func!
func _ready():
	var debug_armor: EquipableItem = load("res://Resources/Items/Equipment/Armor/debugger_armor.tres")
	var debug_weapon: EquipableItem = load("res://Resources/Items/Equipment/Weapons/debugger_weapon.tres")
	var debug_trinket: EquipableItem = load("res://Resources/Items/Equipment/Trinkets/debugger_trinket.tres")
	add_item(debug_armor)
	add_item(debug_weapon)
	add_item(debug_trinket)
	
	check_and_equip_fallback()


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
func add_item(item) -> void:
	player_inventory.append(item)
	print("📦 Added item:", item)
	emit_signal("inventory_changed", "add", item)

func remove_item(item) -> bool:
	if player_inventory.has(item):
		player_inventory.erase(item)
		print("🗑️ Removed item:", item)
		emit_signal("inventory_changed", "remove", item)
		return true
	print("❌ Tried to remove item not in inventory:", item)
	return false

func has_item(item) -> bool:
	return player_inventory.has(item)


# ─────────────────────────────────────────────────────────────
# Equipable gear

var equipped_weapon: EquipableItem = null
var equipped_armor: EquipableItem = null
var equipped_trinkets: Array[EquipableItem] = []

func equip_weapon(item: EquipableItem) -> void:
	print("🧪 Equipped weapon:", GameState.equipped_weapon)
	if item.item_type != "weapon":
		push_error("Trying to equip non-weapon as weapon.")
		return
	equipped_weapon = item
	fallback_equipped.emit() #FALLBACK WEAPON AKA UNARMED

func equip_armor(item: EquipableItem) -> void:
	if item.item_type != "armor":
		push_error("Trying to equip non-armor as armor.")
		return
	equipped_armor = item
	fallback_equipped.emit() #FALLBACK ARMOR AKA NAKED

func equip_trinket(item: EquipableItem) -> void:
	if item.item_type != "trinket":
		push_error("Trying to equip non-trinket as trinket.")
		return
	if not equipped_trinkets.has(item):
		equipped_trinkets.append(item)

func unequip_trinket(item: EquipableItem) -> void:
	equipped_trinkets.erase(item)


func check_and_equip_fallback() -> void:
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
