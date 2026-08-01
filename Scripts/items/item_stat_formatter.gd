class_name ItemStatFormatter
extends RefCounted

## Derives display-ready stat lines for an inventory item.
##
## Items carry no damage or block numbers of their own. A weapon's power is
## emergent from the tiles in its [TileBundle], so every figure the inspector
## shows is computed here rather than authored per item. That keeps the numbers
## honest when a tile is retuned.
##
## Every entry point is static and takes only an [InventoryItem], so the barter
## screen can quote the same figures without duplicating the maths.

const COLOR_GOOD := "#7bbf5a"
const COLOR_DAMAGE := "#c66b4d"
const COLOR_NEUTRAL := "#d6cbb0"

## Heal tiles are authored as [constant Tile.Type.POWER] (see
## Resources/Tiles/Generic/heal_tile.gd), so the enum alone cannot tell a heal
## from a buff. Matching on the script path is the only reliable test until
## Tile.Type gains a HEAL value.
##
## Compared as a string rather than preloaded, because .clinerules/startup-loading.md
## bans preload() in class_name scripts.
const HEAL_TILE_SCRIPT_PATH := "res://Resources/Tiles/Generic/heal_tile.gd"


## Display rows for the inspector, as [{label, value, color}].
static func get_stat_lines(item: InventoryItem) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	if item == null:
		return lines

	if item is EquipableItem:
		lines.append_array(_equipable_lines(item as EquipableItem))

	var value_line := _value_line(item)
	if not value_line.is_empty():
		lines.append(value_line)

	return lines


static func _equipable_lines(item: EquipableItem) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	var stats := analyse_bundle(item.tile_bundle)

	if item.armor_points > 0:
		lines.append(_line("Armor", str(item.armor_points), COLOR_GOOD))

	if stats.attack_count > 0:
		lines.append(_line("Damage", _range_text(stats.damage_min, stats.damage_max), COLOR_DAMAGE))
		lines.append(_line("Average", "%.1f per tile" % stats.avg_damage_per_tile, COLOR_DAMAGE))

	if stats.block_total > 0:
		lines.append(_line("Block", _range_text(stats.block_min, stats.block_max), COLOR_GOOD))

	if stats.heal_total > 0:
		lines.append(_line("Restores", "%d health" % stats.heal_total, COLOR_GOOD))

	if stats.tile_count > 0:
		lines.append(_line("Reliability", "%d%% of draws land" % stats.hit_rate_percent, COLOR_NEUTRAL))
		lines.append(_line("Adds to pile", "%d tiles" % stats.tile_count, COLOR_NEUTRAL))

	if item.hand_slot == "2-handed":
		lines.append(_line("Grip", "Two-handed", COLOR_NEUTRAL))
	elif item.hand_slot == "1-handed":
		lines.append(_line("Grip", "One-handed", COLOR_NEUTRAL))

	return lines


## Raw figures behind the display lines. Public so a future comparison view can
## use them without re-parsing formatted strings.
static func analyse_bundle(bundle: TileBundle) -> Dictionary:
	var stats := {
		tile_count = 0,
		attack_count = 0,
		fail_count = 0,
		damage_min = 0, damage_max = 0, damage_total = 0,
		block_min = 0, block_max = 0, block_total = 0,
		heal_total = 0,
		hit_rate_percent = 0,
		avg_damage_per_tile = 0.0,
	}
	if bundle == null or bundle.tiles.is_empty():
		return stats

	var damage_values: Array[int] = []
	var block_values: Array[int] = []

	for tile in bundle.tiles:
		if tile == null:
			continue
		stats.tile_count += 1

		match tile.type:
			Tile.Type.ATTACK:
				stats.attack_count += 1
				damage_values.append(tile.effect_amount)
				stats.damage_total += tile.effect_amount
				# Combo strike-block tiles carry their block in the secondary
				# slot, so count it as block too. See strike_block_tile.gd.
				if tile.secondary_effect_amount > 0:
					block_values.append(tile.secondary_effect_amount)
					stats.block_total += tile.secondary_effect_amount
			Tile.Type.DEFEND:
				block_values.append(tile.effect_amount)
				stats.block_total += tile.effect_amount
			Tile.Type.FAIL:
				stats.fail_count += 1
			Tile.Type.POWER:
				if _is_heal_tile(tile):
					stats.heal_total += tile.effect_amount

	if not damage_values.is_empty():
		stats.damage_min = damage_values.min()
		stats.damage_max = damage_values.max()
	if not block_values.is_empty():
		stats.block_min = block_values.min()
		stats.block_max = block_values.max()

	stats.hit_rate_percent = int(round(
		float(stats.tile_count - stats.fail_count) / float(stats.tile_count) * 100.0))
	stats.avg_damage_per_tile = float(stats.damage_total) / float(stats.tile_count)

	return stats


## Rough "how strong is this pile" score for the Tile Pile header.
##
## Replaces a flat +86 per POWER tile, which made a single heal trinket swamp
## the whole score while ordinary tiles are worth 1 to 8.
static func calculate_pile_power(tiles: Array[Tile]) -> float:
	if tiles.is_empty():
		return 0.0

	var total: float = 0.0
	for tile in tiles:
		if tile == null:
			continue
		match tile.type:
			Tile.Type.ATTACK, Tile.Type.DEFEND:
				total += tile.effect_amount
				total += tile.secondary_effect_amount * 0.5
			Tile.Type.POWER:
				# A point of healing is worth roughly half a point of damage.
				total += tile.effect_amount * 0.5
			Tile.Type.FAIL:
				total -= 0.5
			_:
				pass

	var final_score := (total / tiles.size()) * 10.0
	return round(final_score * 10) / 10.0


static func _is_heal_tile(tile: Tile) -> bool:
	var script: Script = tile.get_script()
	return script != null and script.resource_path == HEAL_TILE_SCRIPT_PATH


static func _value_line(item: InventoryItem) -> Dictionary:
	if not item.is_sellable():
		return {}

	var parts: Array[String] = []
	if item.sell_price_ore > 0:
		parts.append("%d %s" % [item.sell_price_ore, GameState.ORE_SYMBOL])
	if item.sell_price_crowns > 0:
		parts.append("%d %s" % [item.sell_price_crowns, GameState.CROWN_SYMBOL])
	if item.sell_price_drots > 0:
		parts.append("%d %s" % [item.sell_price_drots, GameState.DROT_SYMBOL])

	return _line("Worth", ", ".join(parts), COLOR_NEUTRAL)


static func _line(label: String, value: String, color: String) -> Dictionary:
	return {label = label, value = value, color = color}


static func _range_text(low: int, high: int) -> String:
	return str(low) if low == high else "%d - %d" % [low, high]
