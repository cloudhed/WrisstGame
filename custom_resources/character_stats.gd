class_name CharacterStats
extends Stats

@export var starting_deck: TilePile
@export var tiles_per_turn: int
@export var max_stamina: int

var stamina: int : set = set_stamina
var deck: TilePile
var discard: TilePile
var draw_pile: TilePile
var combat_statuses: Dictionary = {}


func set_stamina(value: int) -> void:
	if stamina == value:
		return # Don't emit if nothing changed

	print("[DEBUG] Stamina changed from", stamina, "to", value)
	stamina = value
	stats_changed.emit()


func reset_stamina() -> void:
	
	self.stamina = max_stamina


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func can_play_tile(tile: Tile) -> bool:
	return stamina >= tile.cost


func has_status(status_id: StringName) -> bool:
	return combat_statuses.has(status_id)


func get_status(status_id: StringName) -> Dictionary:
	if not has_status(status_id):
		return {}
	return (combat_statuses[status_id] as Dictionary).duplicate(true)


func add_status(status_id: StringName, status_data: Dictionary) -> void:
	var merged := get_status(status_id)
	for key in status_data.keys():
		merged[key] = status_data[key]
	combat_statuses[status_id] = merged
	stats_changed.emit()


func remove_status(status_id: StringName) -> void:
	if not has_status(status_id):
		return
	combat_statuses.erase(status_id)
	stats_changed.emit()


func apply_start_of_turn_effects(player_node: CombatPlayer) -> void:
	if has_status(&"poison"):
		var poison := get_status(&"poison")
		var poison_damage := int(poison.get("damage", 1))
		var remaining_turns := int(poison.get("remaining_turns", 1))

		if player_node != null and poison_damage > 0:
			player_node.take_damage(poison_damage)

		remaining_turns -= 1
		if remaining_turns > 0:
			poison["remaining_turns"] = remaining_turns
			combat_statuses[&"poison"] = poison
		else:
			combat_statuses.erase(&"poison")

		stats_changed.emit()


func get_tiles_to_draw_this_turn() -> int:
	var draw_amount := tiles_per_turn
	if has_status(&"rattled"):
		var rattled := get_status(&"rattled")
		draw_amount = min(draw_amount, int(rattled.get("draw_amount", 2)))
	return max(draw_amount, 0)


func consume_turn_draw_modifiers() -> void:
	if has_status(&"rattled"):
		remove_status(&"rattled")


func add_temporary_tiles_to_pile(target_pile: StringName, tile: Tile, copies: int) -> void:
	if tile == null or copies <= 0:
		return

	var pile: TilePile = null
	match String(target_pile):
		"draw_pile":
			pile = draw_pile
		"discard":
			pile = discard
		"deck":
			pile = deck

	if pile == null:
		return

	for i in range(copies):
		pile.add_tile(tile.duplicate(true))


func get_debug_status_summary() -> String:
	if combat_statuses.is_empty():
		return "None"

	var summaries: PackedStringArray = []
	for status_id in combat_statuses.keys():
		var status_data: Dictionary = combat_statuses[status_id]
		var bits: PackedStringArray = [String(status_id)]
		for key in status_data.keys():
			bits.append("%s=%s" % [String(key), str(status_data[key])])
		summaries.append("%s" % ", ".join(bits))

	return " | ".join(summaries)


func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.player_name = player_name
	instance.health = max_health
	instance.block = 0
	instance.reset_stamina()

	# Use the logical deck created from equipment
	instance.deck = PileManager.get_logical_deck()

	# Create empty draw/discard piles for combat (will be populated later)
	instance.draw_pile = TilePile.new()
	instance.discard = TilePile.new()
	instance.combat_statuses = {}

	return instance
