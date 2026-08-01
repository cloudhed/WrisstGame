extends Node

const PLAYER_STATISTICS_SCRIPT := preload("res://Scripts/autoload/player_statistics.gd")

signal money_changed(currency: String, new_amount: int)
signal reputation_changed(npc_id: String, new_value: int)
signal horny_changed(npc_id: String, new_value: int)
signal inventory_changed(action: String, item)
signal logbook_updated(entry_id: String)
signal fallback_equipped
signal combat_debug_settings_changed
signal health_changed(current: int, maximum: int)
signal state_restored  # bulk state change (save loaded / new game) — UI should refresh silently, no toasts

@export var grant_debug_starting_items: bool = true
@export var debug_immediate_discard_reshuffle: bool = false

# ─────────────────────────────────────────────────────────────
# Player identity
var player_name: String = "MilkshakeMan"
var player_gender: String = "male" # "female" or "male"

# Content settings — toggled in character creation / options menu
# Default is false (everything shown). Player opts OUT by setting to true.
var content_settings: Dictionary = {
	"feral": false,     # true = player opted out of feral/beast erotic content
	"violence": false,  # true = player opted out of violence (erotic, gore, forced)
}
#var player_body_type: String = "curvy" # or "flat", "androgynous", etc.
#var player_pronouns: Dictionary = {
#	"they": "she",
#	"them": "her",
#	"their": "her"
#}

# DEFAULT FALLBACK NAKED&CONFUSED
const FALLBACK_ARMOR_PATH := "res://Resources/Items/Equipment/Armor/naked_armor.tres"
const FALLBACK_WEAPON_PATH := "res://Resources/Items/Equipment/Weapons/unarmed_weapon.tres" #default is unarmed_weapon.tres

var FALLBACK_ARMOR: EquipableItem = null
var FALLBACK_WEAPON: EquipableItem = null
# FAILS FOR SOME REASON, CONST BEING PISSY ABOUT MY ARMOR RESOURCE NOT BEING A EQUIPABLEITEM EVEN THOUGH IT IS const FALLBACK_ARMOR := preload("res://Resources/Items/Equipment/Armor/fallback_naked_armor.res")
# const FALLBACK_WEAPON := preload("res://Resources/Items/Equipment/Weapons/fallback_unarmed_weapon.res")


# Player stats and resources
var player_stats: CharacterStats = null
var player_statistics: Resource = null
# Currency display symbols
const ORE_SYMBOL: String    = "◆"
const CROWN_SYMBOL: String  = "◇"
const DROT_SYMBOL: String   = "◈"

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

# Time of day — global toggle for day/night scene routing
var is_night: bool = false

# NPC relationship points
var npc_reputation: Dictionary = {}
var npc_horny: Dictionary = {}

# Logbook — tracks which entries have been revealed and their status
# Key: entry_id (String), Value: "active" or "complete"
var logbook_entries: Dictionary = {}

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
			player_stats.health = player_stats.max_health
			print("✅ player_stats loaded from player.tres (HP: %d/%d)" % [player_stats.health, player_stats.max_health])

	if grant_debug_starting_items:
		_grant_debug_starting_items()

	check_and_equip_fallback()


func _grant_debug_starting_items() -> void:
	var debug_armor: EquipableItem = load("res://Resources/Items/Equipment/Armor/debugger_armor.tres")
	var debug_weapon: EquipableItem = load("res://Resources/Items/Equipment/Weapons/debugger_weapon.tres")
	var debug_trinket: EquipableItem = load("res://Resources/Items/Equipment/Trinkets/debugger_trinket.tres")
	var debug_longstick: EquipableItem = load("res://Resources/Items/Equipment/Weapons/long_stick_weapon.tres")
	add_item(debug_armor)
	add_item(debug_weapon)
	add_item(debug_longstick)
	add_item(debug_trinket)


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


func get_item_count(item: InventoryItem) -> int:
	for slot in player_inventory:
		if slot.item == item:
			return slot.amount
	return 0


# ─────────────────────────────────────────────────────────────
# Equipable gear

var equipped_weapon: EquipableItem = null
var equipped_armor: EquipableItem = null
var equipped_offhand: EquipableItem = null
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

	# 2-handed weapons lock out the offhand slot
	if item.hand_slot == "2-handed" and equipped_offhand != null:
		unequip_offhand()
		print("⚔️ 2H weapon equipped — offhand cleared")

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

func equip_offhand(item: EquipableItem) -> void:
	if item.equip_type != "offhand":
		push_error("Trying to equip non-offhand as offhand.")
		return

	# Can't equip offhand with a 2-handed weapon
	if equipped_weapon and equipped_weapon.hand_slot == "2-handed":
		print("⚠️ Can't equip offhand — current weapon is 2-handed:", equipped_weapon.name)
		return

	if equipped_offhand and equipped_offhand != item:
		print("🛡️ Unequipping previous offhand:", equipped_offhand.name)

	equipped_offhand = item
	print("🛡️ Equipped offhand:", item.name)
	fallback_equipped.emit()

func unequip_offhand() -> void:
	equipped_offhand = null
	fallback_equipped.emit()

func unequip_trinket(item: EquipableItem) -> void:
	equipped_trinkets.erase(item)
	# Every other equip and unequip path emits this, and the inventory relies on
	# it to refresh. Without it, removing a trinket left the UI stale.
	fallback_equipped.emit()


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
# NPC horny management
func add_horny(npc_id: String, amount: int) -> void:
	var nw = npc_horny.get(npc_id, 0) + amount
	npc_horny[npc_id] = nw
	emit_signal("horny_changed", npc_id, nw)

func remove_horny(npc_id: String, amount: int) -> bool:
	var old = npc_horny.get(npc_id, 0)
	if amount > old:
		return false
	var nw = old - amount
	npc_horny[npc_id] = nw
	emit_signal("horny_changed", npc_id, nw)
	return true

func get_horny(npc_id: String) -> int:
	return npc_horny.get(npc_id, 0)


# ─────────────────────────────────────────────────────────────
# Logbook management

func add_logbook_entry(entry_id: String) -> void:
	if not LogbookData.has_entry(entry_id):
		push_warning("⚠️ Logbook entry not in LogbookData: " + entry_id)
		return
	if logbook_entries.has(entry_id):
		return  # already added
	logbook_entries[entry_id] = "active"
	# Auto-add parent if it hasn't been added yet
	var parent_id: String = LogbookData.get_entry(entry_id).get("parent", "")
	if not parent_id.is_empty() and not logbook_entries.has(parent_id):
		logbook_entries[parent_id] = "active"
		logbook_updated.emit(parent_id)
	logbook_updated.emit(entry_id)
	print("📓 Logbook entry added: " + entry_id)


func complete_logbook_entry(entry_id: String) -> void:
	if not logbook_entries.has(entry_id):
		push_warning("⚠️ Logbook entry not found: " + entry_id)
		return
	logbook_entries[entry_id] = "complete"
	logbook_updated.emit(entry_id)
	print("📓 Logbook entry completed: " + entry_id)


func get_logbook_status(entry_id: String) -> String:
	return logbook_entries.get(entry_id, "")


# ─────────────────────────────────────────────────────────────
# Generic flag helpers (quests, dialogs, events)
func set_flag(flag_dict: Dictionary, key: String) -> void:
	flag_dict[key] = true

func clear_flag(flag_dict: Dictionary, key: String) -> void:
	flag_dict.erase(key)

func has_flag(flag_dict: Dictionary, key: String) -> bool:
	return flag_dict.has(key) and flag_dict[key] == true


# ─────────────────────────────────────────────────────────────
# Player health — persistent across combat encounters
# GameState.player_stats.health is the single source of truth.

## Save combat result back to persistent health. Called on victory, defeat, and flee.
func set_player_health(value: int) -> void:
	if player_stats == null:
		push_error("❌ set_player_health called but player_stats is null!")
		return
	player_stats.health = clampi(value, 0, player_stats.max_health)
	health_changed.emit(player_stats.health, player_stats.max_health)


## Heal the player by [amount] HP, clamped to max. Used by town services, consumables, etc.
func heal_player(amount: int) -> void:
	if player_stats == null:
		return
	var before := player_stats.health
	player_stats.health = clampi(player_stats.health + amount, 0, player_stats.max_health)
	if player_stats.health != before:
		health_changed.emit(player_stats.health, player_stats.max_health)
		print("💚 Healed %d HP → %d/%d" % [player_stats.health - before, player_stats.health, player_stats.max_health])


## Fully restore health. Used by Bwavrek's hotbaths, debug, new-game reset.
func heal_player_full() -> void:
	if player_stats == null:
		return
	set_player_health(player_stats.max_health)
	print("💚 Full heal → %d/%d" % [player_stats.health, player_stats.max_health])


# ─────────────────────────────────────────────────────────────
# Save / load serialization — called by SaveManager.
# Items and equipment are stored as their .tres resource paths, so a loaded
# item is the same cached Resource instance the rest of the game uses
# (which keeps `slot.item == item` identity checks working).

func to_dict() -> Dictionary:
	var inventory_out: Array = []
	for slot in player_inventory:
		var item: InventoryItem = slot.get("item")
		if item == null or item.resource_path.is_empty():
			push_warning("💾 Inventory item without a resource path can't be saved — skipped.")
			continue
		inventory_out.append({"path": item.resource_path, "amount": int(slot.get("amount", 1))})

	var trinket_paths: Array = []
	for trinket in equipped_trinkets:
		if trinket != null and not trinket.resource_path.is_empty():
			trinket_paths.append(trinket.resource_path)

	return {
		"player_name": player_name,
		"player_gender": player_gender,
		"content_settings": content_settings.duplicate(),
		"health": player_stats.health if player_stats != null else -1,
		"currency": {"ore": player_ore, "crowns": player_crowns, "drots": player_drots},
		"inventory": inventory_out,
		"equipment": {
			"weapon": _equipped_path(equipped_weapon),
			"armor": _equipped_path(equipped_armor),
			"offhand": _equipped_path(equipped_offhand),
			"trinkets": trinket_paths,
		},
		"flags": {
			"quest": quest_flags.duplicate(),
			"dialog": dialog_flags.duplicate(),
			"event": event_flags.duplicate(),
			"knowledge": knowledge_flags.duplicate(),
			"sex": sex_flags.duplicate(),
			"temp": temp_flags.duplicate(),
		},
		"npc_reputation": npc_reputation.duplicate(),
		"npc_horny": npc_horny.duplicate(),
		"logbook": logbook_entries.duplicate(),
		"is_night": is_night,
		"statistics": player_statistics.to_dict() if player_statistics != null else {},
		"debug": {
			"immediate_discard_reshuffle": debug_immediate_discard_reshuffle,
		},
	}


func from_dict(data: Dictionary) -> void:
	player_name = str(data.get("player_name", player_name))
	player_gender = str(data.get("player_gender", player_gender))

	# Only copy known content-setting keys so stale save data can't add new ones.
	var loaded_content: Dictionary = data.get("content_settings", {})
	for key in content_settings:
		content_settings[key] = bool(loaded_content.get(key, content_settings[key]))

	var currency: Dictionary = data.get("currency", {})
	player_ore = int(currency.get("ore", 0))
	player_crowns = int(currency.get("crowns", 0))
	player_drots = int(currency.get("drots", 0))

	player_inventory.clear()
	for entry in data.get("inventory", []):
		var item := _load_saved_item(str(entry.get("path", "")))
		if item != null:
			player_inventory.append({"item": item, "amount": int(entry.get("amount", 1))})

	var equipment: Dictionary = data.get("equipment", {})
	equipped_weapon = _load_saved_item(str(equipment.get("weapon", ""))) as EquipableItem
	equipped_armor = _load_saved_item(str(equipment.get("armor", ""))) as EquipableItem
	equipped_offhand = _load_saved_item(str(equipment.get("offhand", ""))) as EquipableItem
	equipped_trinkets.clear()
	for trinket_path in equipment.get("trinkets", []):
		var trinket := _load_saved_item(str(trinket_path)) as EquipableItem
		if trinket != null:
			equipped_trinkets.append(trinket)

	var flags: Dictionary = data.get("flags", {})
	quest_flags = flags.get("quest", {})
	dialog_flags = flags.get("dialog", {})
	event_flags = flags.get("event", {})
	knowledge_flags = flags.get("knowledge", {})
	sex_flags = flags.get("sex", {})
	temp_flags = flags.get("temp", {})

	npc_reputation = _coerce_int_values(data.get("npc_reputation", {}))
	npc_horny = _coerce_int_values(data.get("npc_horny", {}))
	logbook_entries = data.get("logbook", {})
	is_night = bool(data.get("is_night", false))

	if player_statistics == null:
		player_statistics = PLAYER_STATISTICS_SCRIPT.new()
	player_statistics.from_dict(data.get("statistics", {}))

	var debug_settings: Dictionary = data.get("debug", {})
	debug_immediate_discard_reshuffle = bool(debug_settings.get("immediate_discard_reshuffle", debug_immediate_discard_reshuffle))

	check_and_equip_fallback()  # covers missing gear + emits fallback_equipped for the UI
	var saved_health := int(data.get("health", -1))
	if saved_health >= 0:
		set_player_health(saved_health)

	# Silent bulk refresh — money_changed would toast "gained 0" popups here.
	combat_debug_settings_changed.emit()
	state_restored.emit()
	print("💾 GameState restored from save data.")


## Wipe all progress back to a fresh start. Called by SaveManager.new_game().
func reset_for_new_game() -> void:
	player_ore = 0
	player_crowns = 0
	player_drots = 0
	player_inventory.clear()
	equipped_weapon = null
	equipped_armor = null
	equipped_offhand = null
	equipped_trinkets.clear()
	quest_flags.clear()
	dialog_flags.clear()
	event_flags.clear()
	knowledge_flags.clear()
	sex_flags.clear()
	temp_flags.clear()
	npc_reputation.clear()
	npc_horny.clear()
	logbook_entries.clear()
	is_night = false
	last_scene_id = ""
	return_to_scene = null
	pending_dialog_scene_data = null
	player_statistics = PLAYER_STATISTICS_SCRIPT.new()

	# Same setup a first boot gets.
	if grant_debug_starting_items:
		_grant_debug_starting_items()
	check_and_equip_fallback()
	heal_player_full()

	state_restored.emit()  # silent bulk refresh — no "gained 0" toasts
	print("🔄 GameState reset for new game.")


func _equipped_path(item: EquipableItem) -> String:
	return item.resource_path if item != null else ""


func _load_saved_item(path: String) -> InventoryItem:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		push_warning("💾 Saved item no longer exists in the project: " + path)
		return null
	return load(path) as InventoryItem


func _coerce_int_values(src: Dictionary) -> Dictionary:
	# JSON round-trips every number as a float — convert them back to ints.
	var out := {}
	for key in src:
		out[key] = int(src[key])
	return out


func toggle_debug_immediate_discard_reshuffle() -> void:
	debug_immediate_discard_reshuffle = not debug_immediate_discard_reshuffle
	combat_debug_settings_changed.emit()


func get_debug_reshuffle_mode_label() -> String:
	return "Immediate discard reshuffle" if debug_immediate_discard_reshuffle else "Cycle deck before reshuffle"
