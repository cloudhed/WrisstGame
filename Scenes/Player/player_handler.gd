class_name PlayerHandler
extends Node

const HAND_DRAW_INTERVAL := 0.25
const HAND_DISCARD_INTERVAL := 0.1

@export var hand: Hand

var combat_player: CombatPlayer
var stats_ui: StatsUI
var character: CharacterStats


func _ready() -> void:
	Events.tile_played.connect(_on_tile_played)


func start_combat(char_stats: CharacterStats) -> void:
	print("Player_handler starting combat")
	character = char_stats

	# Let PileManager set up draw and discard piles
	PileManager.create_combat_piles(character)

	# Assign player stats
	combat_player.stats = character
	combat_player.assign_stats_ui(stats_ui)

	start_turn()

var turn_blocked := false

func start_turn() -> void:
	var combat = get_tree().get_current_scene() as Combat
	if combat and combat.combat_over:
		print("⛔ Combat is over — skipping player start_turn.")
		return
	
	if turn_blocked:
		print("[DEBUG] Turn is currently blocked, not starting turn.")
		return

	print("Starting player turn.")
	character.block = 0
	character.reset_stamina()
	draw_tiles(character.tiles_per_turn)


func end_turn() -> void:
	print("Ending player turn.")
	hand.disable_hand()
	discard_tiles()


func draw_tile() -> void:
	reshuffle_deck_from_discard()
	hand.add_tile(character.draw_pile.draw_tile())
	reshuffle_deck_from_discard()


func draw_tiles(amount: int) -> void:
	print("Starting to draw_tiles.")
	var tween := create_tween()
	for i in range(amount):
		tween.tween_callback(draw_tile)
		tween.tween_interval(HAND_DRAW_INTERVAL)
	
	tween.finished.connect(
		func(): Events.player_hand_drawn.emit()
	)

func discard_tiles() -> void:
	print("Starting to discard_tiles.")
	var tween := create_tween()
	for tile_ui in hand.get_children():
		tween.tween_callback(character.discard.add_tile.bind(tile_ui.tile))
		tween.tween_callback(hand.discard_tile.bind(tile_ui))
		tween.tween_interval(HAND_DISCARD_INTERVAL)

	tween.finished.connect(
		func():
			print("Tween finished, discarded_tiles, going to emit to: Events.player_hand_discarded.emit()")
			Events.player_hand_discarded.emit()
	)


#func reshuffle_deck_from_discard() -> void:
#	if not character.draw_pile.empty(): # I think I wanna remove this for real game
#		return # mostly because draw pile will be the same odds every turn

func reshuffle_deck_from_discard() -> void:
	while not character.discard.empty():
		character.draw_pile.add_tile(character.discard.draw_tile())

	character.draw_pile.shuffle()

	
	while not character.discard.empty():
		character.draw_pile.add_tile(character.discard.draw_tile())

	character.draw_pile.shuffle()


func _on_tile_played(tile: Tile) -> void:
	character.discard.add_tile(tile)
