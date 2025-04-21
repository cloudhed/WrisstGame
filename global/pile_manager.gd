extends Node

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


	var added_any: bool = false


	if GameState.equipped_weapon and GameState.equipped_weapon.tile_bundle:
		for tile in GameState.equipped_weapon.tile_bundle.tiles:
			combined_deck.add_tile(tile)
			added_any = true

	if GameState.equipped_armor and GameState.equipped_armor.tile_bundle:
		for tile in GameState.equipped_armor.tile_bundle.tiles:
			combined_deck.add_tile(tile)
			added_any = true

	for trinket in GameState.equipped_trinkets:
		if trinket.tile_bundle:
			for tile in trinket.tile_bundle.tiles:
				combined_deck.add_tile(tile)
				added_any = true

	if not added_any:
		# No equipment? Use fallback starter deck
		var starter_deck: TilePile = preload("res://Characters/Player/tiles/player_starting_deck.tres")
		for tile in starter_deck.tiles:
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
