extends Node

const STARTER_DECK_PATH := "res://Characters/Player/tiles/player_starting_deck.tres"
var _starter_deck_cache: TilePile = null


func _get_starter_deck() -> TilePile:
	if _starter_deck_cache == null:
		_starter_deck_cache = load(STARTER_DECK_PATH) as TilePile
		if _starter_deck_cache == null:
			push_error("❌ Failed to load starter deck: " + STARTER_DECK_PATH)
	return _starter_deck_cache

## The tiles the player's current gear contributes, with no side effects.
##
## Offhands (shields) contribute tiles; armor deliberately does NOT, because it
## is passive armor_points instead.
##
## Do NOT call get_logical_deck() from UI code. It equips fallback gear, which
## emits fallback_equipped, which re-enters the UI refresh and recurses. Use
## this instead: it is the same tile list without the equipping.
func get_preview_tiles() -> Array[Tile]:
	var tiles: Array[Tile] = []

	if GameState.equipped_weapon and GameState.equipped_weapon.tile_bundle:
		tiles.append_array(GameState.equipped_weapon.tile_bundle.tiles)

	if GameState.equipped_offhand and GameState.equipped_offhand.tile_bundle:
		tiles.append_array(GameState.equipped_offhand.tile_bundle.tiles)

	for trinket in GameState.equipped_trinkets:
		if trinket.tile_bundle:
			tiles.append_array(trinket.tile_bundle.tiles)

	if tiles.is_empty():
		# No equipment contributes anything? Fall back to the starter deck.
		var starter_deck: TilePile = _get_starter_deck()
		if starter_deck != null:
			tiles.append_array(starter_deck.tiles)

	return tiles


func get_logical_deck() -> TilePile:
	var combined_deck := TilePile.new()

# Equip fallback armor if none
	if GameState.equipped_armor == null:
		GameState.equip_armor(GameState.FALLBACK_ARMOR)
		print("🧥 Fallback armor equipped:", GameState.FALLBACK_ARMOR.name)

# Equip fallback weapon if none
	if GameState.equipped_weapon == null:
		GameState.equip_weapon(GameState.FALLBACK_WEAPON)
		print("🧤 Fallback weapon equipped:", GameState.FALLBACK_WEAPON.name)

	for tile in get_preview_tiles():
		combined_deck.add_tile(tile)

	return combined_deck


func create_combat_piles(char_stats: CharacterStats) -> void:
	char_stats.deck = get_logical_deck()
	char_stats.draw_pile = char_stats.deck.duplicate(true)
	char_stats.draw_pile.shuffle()
	char_stats.discard = TilePile.new()


func get_deck_preview() -> PackedStringArray:
	var result: PackedStringArray = []
	var deck: TilePile = get_logical_deck()

	for tile in deck.tiles:
		result.append("%s (%s)" % [tile.id, tile.type])

	return result
