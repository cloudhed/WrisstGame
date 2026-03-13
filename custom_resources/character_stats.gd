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

const STATUS_POISON := &"poison"
const STATUS_RATTLED := &"rattled"
const STATUS_DRAINED_STAMINA := &"drained_stamina"
const STATUS_SLIMED := &"slimed"


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

	match status_id:
		STATUS_SLIMED:
			merged["stacks"] = int(merged.get("stacks", 0)) + int(status_data.get("stacks", 1))
			merged["dud_tiles_added"] = int(merged.get("dud_tiles_added", 0)) + int(status_data.get("dud_tiles_added", 0))
		_:
			for key in status_data.keys():
				merged[key] = status_data[key]

	combat_statuses[status_id] = merged
	stats_changed.emit()


func remove_status(status_id: StringName) -> void:
	if not has_status(status_id):
		return
	combat_statuses.erase(status_id)
	stats_changed.emit()



func apply_player_turn_start_effects() -> Dictionary:
	var result := {
		"damage_taken": 0,
		"died": false,
	}

	if has_status(STATUS_POISON):
		var poison := get_status(STATUS_POISON)
		var poison_damage := int(poison.get("damage", 1))
		var remaining_turns := int(poison.get("remaining_turns", 1))

		if poison_damage > 0:
			result["damage_taken"] = poison_damage
			take_damage(poison_damage)
			result["died"] = health <= 0

		remaining_turns -= 1
		if remaining_turns > 0:
			poison["remaining_turns"] = remaining_turns
			combat_statuses[STATUS_POISON] = poison
		else:
			combat_statuses.erase(STATUS_POISON)

		stats_changed.emit()

	return result


func get_stamina_for_new_turn() -> int:
	var turn_stamina := max_stamina

	if has_status(STATUS_DRAINED_STAMINA):
		var drained_stamina := get_status(STATUS_DRAINED_STAMINA)
		turn_stamina = min(turn_stamina, int(drained_stamina.get("stamina_amount", turn_stamina)))

	return max(turn_stamina, 0)


func get_tiles_to_draw_this_turn() -> int:
	var draw_amount := tiles_per_turn
	if has_status(STATUS_RATTLED):
		var rattled := get_status(STATUS_RATTLED)
		draw_amount = min(draw_amount, int(rattled.get("draw_amount", 2)))
	return max(draw_amount, 0)


func consume_player_turn_start_modifiers() -> void:
	var changed := false

	if has_status(STATUS_RATTLED):
		changed = _decrement_turn_status(STATUS_RATTLED) or changed

	if has_status(STATUS_DRAINED_STAMINA):
		changed = _decrement_turn_status(STATUS_DRAINED_STAMINA) or changed

	if changed:
		stats_changed.emit()


func _decrement_turn_status(status_id: StringName) -> bool:
	if not has_status(status_id):
		return false

	var status_data := get_status(status_id)
	if not status_data.has("remaining_turns"):
		return false

	var remaining_turns := int(status_data.get("remaining_turns", 0)) - 1
	if remaining_turns > 0:
		status_data["remaining_turns"] = remaining_turns
		combat_statuses[status_id] = status_data
	else:
		combat_statuses.erase(status_id)

	return true


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


func add_dud_status(copies_added: int, stack_amount: int = 1) -> void:
	add_status(STATUS_SLIMED, {
		"stacks": max(stack_amount, 1),
		"dud_tiles_added": max(copies_added, 0)
	})


func get_debug_status_summary() -> String:
	if combat_statuses.is_empty():
		return "None"

	var summaries: PackedStringArray = []
	for status_id in combat_statuses.keys():
		var status_data: Dictionary = combat_statuses[status_id]
		summaries.append(_format_status_summary(status_id, status_data))

	return " | ".join(summaries)


func _format_status_summary(status_id: StringName, status_data: Dictionary) -> String:
	match status_id:
		STATUS_POISON:
			return "poison %st dmg=%s" % [status_data.get("remaining_turns", "?"), status_data.get("damage", 1)]
		STATUS_RATTLED:
			return "rattled %st draw=%s" % [status_data.get("remaining_turns", "?"), status_data.get("draw_amount", 2)]
		STATUS_DRAINED_STAMINA:
			return "drained stamina %st -> %s" % [status_data.get("remaining_turns", "?"), status_data.get("stamina_amount", 0)]
		STATUS_SLIMED:
			var stacks := int(status_data.get("stacks", 1))
			return "slimed" if stacks <= 1 else "slimed x%s" % stacks
		_:
			var bits: PackedStringArray = [String(status_id)]
			for key in status_data.keys():
				bits.append("%s=%s" % [String(key), str(status_data[key])])
			return ", ".join(bits)


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
