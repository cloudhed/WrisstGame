# combat.gd
class_name Combat
extends Node2D

@export var char_stats: CharacterStats
@export var music: AudioStream
@export var auto_leave_on_victory: bool = true
const DIALOG_SCENE_PATH := "res://Narrative/DialogScene.tscn"


@onready var combat_ui: CombatUI = $CombatUI as CombatUI
@onready var player_handler: PlayerHandler = $PlayerHandler as PlayerHandler
@onready var enemy_handler: EnemyHandler = $EnemyHandler as EnemyHandler
@onready var player: CombatPlayer = $PlayerHandler/CombatPlayer as CombatPlayer

var created_stats: CharacterStats
var combat_over: bool = false
var combat_aborted: bool = false
var combat_result_recorded: bool = false
var dialog_overlay: DialogManager = null
var active_enemy_stats: EnemyStats = null

#enemy_loading_through_JSON
var override_enemy_resource: Resource = null

signal combat_ended


func setup_with_enemy(enemy_res: Resource) -> void:
	override_enemy_resource = enemy_res


func _ready() -> void:
	combat_ui.visible = false
	$IntentUI.visible = false

	if override_enemy_resource == null and Manager.has_method("consume_selected_enemy_resource"):
		var encounter_enemy: EnemyStats = Manager.consume_selected_enemy_resource()
		if encounter_enemy != null:
			override_enemy_resource = encounter_enemy

	if char_stats == null:
		print("⚠️ char_stats is null in _ready(). Using fallback GameState.player_stats.")
		char_stats = GameState.player_stats
		
	# Only create stats ONCE
	created_stats = char_stats.create_instance()
	combat_ui.char_stats = created_stats

	# UI setup
	player_handler.combat_player = player
	player_handler.stats_ui = %StatsUIPlayer
	enemy_handler.enemy_ui = %StatsUIEnemy

	# Signal hooks
	Events.player_ready.connect(_on_player_ready)
	enemy_handler.child_order_changed.connect(_on_enemies_child_order_changed)
	Events.enemy_defeated.connect(_on_enemies_child_order_changed)
	Events.enemy_turn_ended.connect(_on_enemy_turn_ended)
	Events.player_turn_ended.connect(player_handler.end_turn)
	Events.player_hand_discarded.connect(enemy_handler.start_turn)
	Events.player_died.connect(_on_player_died)

	_setup_enemy()

# res://Scenes/Enemy/enemy.tscn

func _setup_enemy() -> void:
	var enemy: Enemy  # ✅ declare outside, for strict typing

	# 💣 CLEAR all existing enemies first
	#for child in enemy_handler.get_children():
		#child.queue_free()

	if override_enemy_resource:
				# 💣 CLEAR all existing enemies first
		for child in enemy_handler.get_children():
			child.queue_free()
		# 🪄 Create fresh enemy scene + set resource
		var enemy_scene: PackedScene = preload("res://Scenes/Enemy/enemy.tscn")  # your actual path
		enemy = enemy_scene.instantiate() as Enemy
		enemy_handler.add_child(enemy)
		enemy.stats = override_enemy_resource
		print("✅ Enemy spawned from override resource:", enemy.name)
	else:
		# 🧑‍💻 Fallback for debug / editor mode
		enemy = enemy_handler.get_child(0) as Enemy
		if not enemy:
			print("❌ No enemy found in enemy_handler or override.")
			return
		print("✅ Enemy found from editor:", enemy.name)

	enemy.intent_ui = $IntentUI
	active_enemy_stats = enemy.stats as EnemyStats
	combat_ui.set_run_enabled(active_enemy_stats == null or active_enemy_stats.is_runnable)
	_start_precombat_or_combat()


func _start_precombat_or_combat() -> void:
	if active_enemy_stats and not active_enemy_stats.pre_combat_dialog_path.is_empty():
		_show_dialog_overlay(active_enemy_stats.pre_combat_dialog_path, active_enemy_stats.slide_deck)
	else:
		start_combat(created_stats)


func _build_overlay_dialog_scene_data(dialog_path: String, deck: SlideDeck = null) -> DialogSceneResource:
	var data := DialogSceneResource.new()
	data.dialogue_path = dialog_path
	data.characters = []
	data.slide_deck = deck
	data.flags_required = []
	data.flags_set_on_start = {}
	return data


func _show_dialog_overlay(dialog_path: String, deck: SlideDeck = null) -> void:
	if dialog_path.is_empty():
		return

	if dialog_overlay:
		dialog_overlay.queue_free()
		dialog_overlay = null

	combat_ui.visible = false
	$IntentUI.visible = false

	var dialog_scene: PackedScene = load(DIALOG_SCENE_PATH) as PackedScene
	if dialog_scene == null:
		push_error("❌ Combat: failed to load dialog scene overlay: " + DIALOG_SCENE_PATH)
		return

	var overlay := dialog_scene.instantiate() as DialogManager
	if overlay == null:
		push_error("❌ Combat: dialog overlay scene is not DialogManager.")
		return

	overlay.dialog_scene_data = _build_overlay_dialog_scene_data(dialog_path, deck)
	add_child(overlay)
	dialog_overlay = overlay


func begin_combat_from_overlay() -> void:
	if dialog_overlay:
		dialog_overlay.queue_free()
		dialog_overlay = null
	start_combat(created_stats)


func _on_player_ready(p: CombatPlayer) -> void:
	var new_stats: CharacterStats = char_stats.create_instance()
	combat_ui.char_stats = new_stats

	p.stats = new_stats
	player = p

func start_combat(stats: CharacterStats) -> void:
	print("⚔️ Combat has started!")
	combat_ui.visible = true
	$IntentUI.visible = true

	MusicPlayer.play(music, true)
	enemy_handler.reset_enemy_actions()
	player_handler.start_combat(stats)

	for enemy in enemy_handler.get_children():
		print("🧟 Enemy:", enemy.name)

func _all_enemies_defeated() -> bool:
	var enemy_count := 0
	for child in enemy_handler.get_children():
		if child is Enemy:
			enemy_count += 1
			if not child.is_defeated:
				return false

	# Empty handler during teardown is not a victory condition.
	return enemy_count > 0

func _on_enemies_child_order_changed() -> void:
	if combat_over or combat_aborted:
		return

	print("Checking enemies_child_order_changed.")

	if _all_enemies_defeated():
		print("🏆 Victory!")
		_record_combat_result(true)
		combat_over = true
#		combat_ui.visible = false
		$IntentUI.visible = false
		if active_enemy_stats and not active_enemy_stats.post_combat_dialog_path.is_empty() and not combat_aborted:
			_show_dialog_overlay(active_enemy_stats.post_combat_dialog_path, active_enemy_stats.slide_deck)
			return

		emit_signal("combat_ended")
		if auto_leave_on_victory:
			Events.leave_encounter_requested.emit()
		queue_free()   # ✅ also remove Combat overlay scene
		#Events.leave_encounter_requested.emit()

func _on_enemy_turn_ended() -> void:
	player_handler.turn_blocked = false
	player_handler.start_turn()
	enemy_handler.reset_enemy_actions()

func _on_player_died() -> void:
	print("☠️ Game over!")
	_record_combat_result(false)
	# You can optionally also emit leave_encounter_requested here if you want


func abort_combat() -> void:
	if combat_aborted:
		return

	print("⚠️ abort_combat() CALLED.")
	combat_aborted = true
	combat_over = true
	MusicPlayer.fade_out(0.6)
	if dialog_overlay:
		dialog_overlay.queue_free()
		dialog_overlay = null


func _record_combat_result(won: bool) -> void:
	if combat_result_recorded:
		return

	if active_enemy_stats == null or GameState.player_statistics == null:
		combat_result_recorded = true
		return

	var species_id := active_enemy_stats.get_species_id() if active_enemy_stats.has_method("get_species_id") else StringName("unknown")
	if won:
		GameState.player_statistics.record_win(species_id)
	else:
		GameState.player_statistics.record_loss(species_id)

	combat_result_recorded = true
