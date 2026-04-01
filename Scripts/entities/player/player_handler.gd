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

	if character == null:
		print("⛔ Player character stats missing — skipping player start_turn.")
		return
	
	if turn_blocked:
		print("[DEBUG] Turn is currently blocked, not starting turn.")
		return

	print("Starting player turn.")
	var turn_effects := character.apply_player_turn_start_effects()
	if bool(turn_effects.get("died", false)):
		Events.player_died.emit()
		return

	if character.health <= 0:
		return

	character.block = 0
	character.stamina = character.get_stamina_for_new_turn()
	var tiles_to_draw := character.get_tiles_to_draw_this_turn()
	print("[DEBUG] Turn start resolved — Stamina:", character.stamina, " | Draw:", tiles_to_draw)
	draw_tiles(tiles_to_draw)
	character.consume_player_turn_start_modifiers()


func end_turn() -> void:
	print("Ending player turn.")
	hand.disable_hand()
	discard_tiles()


func draw_tile() -> void:
	_prepare_draw_pile_for_draw()
	if character.draw_pile.empty():
		print("[DEBUG] No more tiles available to draw.")
		return
	hand.add_tile(character.draw_pile.draw_tile())


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
	if hand.get_child_count() == 0:
		print("Hand already empty — emitting player_hand_discarded immediately.")
		Events.player_hand_discarded.emit()
		return

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


func _prepare_draw_pile_for_draw() -> void:
	var immediate_reshuffle := GameState.debug_immediate_discard_reshuffle
	if immediate_reshuffle:
		_reshuffle_deck_from_discard()
		return

	if character.draw_pile.empty():
		_reshuffle_deck_from_discard()


func _reshuffle_deck_from_discard() -> void:
	if character == null or character.discard == null or character.draw_pile == null:
		return

	if character.discard.empty():
		return

	while not character.discard.empty():
		character.draw_pile.add_tile(character.discard.draw_tile())

	character.draw_pile.shuffle()


func _on_tile_played(tile: Tile) -> void:
	if tile.exile_on_play:
		return
	character.discard.add_tile(tile)
