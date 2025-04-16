extends Node

signal money_changed(currency: String, new_amount: int)
signal reputation_changed(npc_id: String, new_value: int)
signal inventory_changed(action: String, item)

# Player stats and resources
var player_stats: CharacterStats = null
var player_ore: int = 0
var player_crowns: int = 0
var player_drots: int = 0
var player_inventory: Array = []

# Flags for quests, dialogs, and events
var quest_flags: Dictionary = {}
var dialog_flags: Dictionary = {}
var event_flags: Dictionary = {}

# NPC relationship points
var npc_reputation: Dictionary = {}

# ─────────────────────────────────────────────────────────────
# Here be the money-stuff!
func add_ore(amount: int) -> void:
	player_ore += amount
	emit_signal("money_changed", "ore", player_ore)

func remove_ore(amount: int) -> bool:
	if amount > player_ore:
		return false
	player_ore -= amount
	emit_signal("money_changed", "ore", player_ore)
	return true


func add_crowns(amount: int) -> void:
	player_crowns += amount
	emit_signal("money_changed", "crowns", player_crowns)

func remove_crowns(amount: int) -> bool:
	if amount > player_crowns:
		return false
	player_crowns -= amount
	emit_signal("money_changed", "crowns", player_crowns)
	return true


func add_drots(amount: int) -> void:
	player_drots += amount
	emit_signal("money_changed", "drots", player_drots)

func remove_drots(amount: int) -> bool:
	if amount > player_drots:
		return false
	player_drots -= amount
	emit_signal("money_changed", "drots", player_drots)
	return true


# ─────────────────────────────────────────────────────────────
# Inventory management
func add_item(item) -> void:
	player_inventory.append(item)
	emit_signal("inventory_changed", "add", item)

func remove_item(item) -> bool:
	if player_inventory.has(item):
		player_inventory.erase(item)
		emit_signal("inventory_changed", "remove", item)
		return true
	return false

func has_item(item) -> bool:
	return player_inventory.has(item)


# ─────────────────────────────────────────────────────────────
# NPC reputation management
func add_reputation(npc_id: String, amount: int) -> void:
	var old = npc_reputation.get(npc_id, 0)
	var nw = old + amount
	npc_reputation[npc_id] = nw
	emit_signal("reputation_changed", npc_id, nw)

func remove_reputation(npc_id: String, amount: int) -> bool:
	var old = npc_reputation.get(npc_id, 0)
	if amount > old:
		return false
	var nw = old - amount
	npc_reputation[npc_id] = nw
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
