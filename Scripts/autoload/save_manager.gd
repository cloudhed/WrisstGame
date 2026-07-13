extends Node
## SaveManager — the whole game in one JSON file (user://save_0.json).
##
## What gets saved:
##  - Everything GameState owns (identity, currencies, inventory, equipment,
##    flags, reputation, logbook, health, statistics) via GameState.to_dict().
##  - AbilitySystem tier assignments.
##  - The overworld snapshot held by Manager (player position, biome, clock).
##
## When it runs:
##  - On boot: if a save file exists it is applied before the main scene's
##    _ready(), so the overworld starts where the player left off ("Continue").
##  - Autosave: every time an encounter/dialog hands control back to the
##    overworld, and when the game window is closed.
##  - Manually: via the debug panel's Save / Load / New Game buttons.

signal game_saved
signal game_loaded

const SAVE_PATH := "user://save_0.json"
const SCHEMA_VERSION := 1
const OVERWORLD_SCENE_PATH := "res://Scenes/overworld/overworldNav.tscn"


func _ready() -> void:
	# Autosave point: by the time this signal fires, combat/dialog has already
	# written its results (health, flags, loot) back to GameState.
	# Deferred so we never save in the middle of the emitting system's cleanup.
	Events.leave_encounter_requested.connect(_on_leave_encounter_requested)

	# Boot-continue: autoloads _ready() before the main scene does, so applying
	# the save here means PlayerDot and the clock restore themselves normally.
	if has_save() and _load_and_apply():
		print("💾 SaveManager: save found — continuing previous game.")


func _notification(what: int) -> void:
	# Window close (X button / Alt+F4) — save before the game shuts down.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


func _on_leave_encounter_requested() -> void:
	call_deferred("save_game")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


## Serialize the full game state and write it to disk. Returns true on success.
func save_game() -> bool:
	var data := {
		"schema_version": SCHEMA_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"gamestate": GameState.to_dict(),
		"abilities": AbilitySystem.get_save_data(),
		"world": _collect_world_state(),
	}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("💾 SaveManager: can't open %s for writing (error %d)." % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	game_saved.emit()
	print("💾 Game saved → " + SAVE_PATH)
	return true


## Manual load (debug panel): apply the save file, then restart the overworld
## so PlayerDot and TimeOfDayControl pick up the restored position and clock.
func load_game() -> bool:
	if not _load_and_apply():
		return false
	_go_to_overworld()
	return true


## Delete the save and reset every system back to a fresh start.
func new_game() -> void:
	if has_save():
		var dir := DirAccess.open("user://")
		if dir != null:
			dir.remove(SAVE_PATH.get_file())

	GameState.reset_for_new_game()
	AbilitySystem.assign_abilities("soul", "body")  # default spread: soul high, mind mid, body low
	Manager.player_last_position = Manager.DEFAULT_PLAYER_START
	Manager.combat_biome = "Default"
	Manager.last_time_of_day = {}
	Manager.last_time_period = "Day"

	print("🔄 New game started — save file removed.")
	_go_to_overworld()


# ─────────────────────────────────────────────────────────────
# Internals

func _load_and_apply() -> bool:
	if not has_save():
		push_warning("💾 SaveManager: no save file to load.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("💾 SaveManager: can't open %s for reading (error %d)." % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()

	if parsed == null or not parsed is Dictionary:
		push_error("💾 SaveManager: save file is corrupt — ignoring it.")
		return false
	var data: Dictionary = parsed

	# Abilities first: GameState.from_dict() fires the UI-refresh signals, so
	# everything those refreshes read from must already be in place.
	# JSON round-trips every number as a float — coerce tier values back to int.
	var abilities: Dictionary = data.get("abilities", {})
	if abilities.has("tier_values"):
		abilities["tier_values"] = _coerce_int_values(abilities["tier_values"])
	AbilitySystem.load_save_data(abilities)

	GameState.from_dict(data.get("gamestate", {}))

	_apply_world_state(data.get("world", {}))

	game_loaded.emit()
	return true


func _collect_world_state() -> Dictionary:
	return {
		"position_x": Manager.player_last_position.x,
		"position_y": Manager.player_last_position.y,
		"biome": Manager.combat_biome,
		"time_of_day": Manager.last_time_of_day.duplicate(),
		"time_period": Manager.last_time_period,
	}


func _apply_world_state(world: Dictionary) -> void:
	Manager.player_last_position = Vector2(
		float(world.get("position_x", Manager.DEFAULT_PLAYER_START.x)),
		float(world.get("position_y", Manager.DEFAULT_PLAYER_START.y))
	)
	Manager.combat_biome = str(world.get("biome", "Default"))
	Manager.last_time_of_day = _coerce_int_values(world.get("time_of_day", {}))
	Manager.last_time_period = str(world.get("time_period", "Day"))


func _go_to_overworld() -> void:
	# Deferred: safe to call from a button press or mid-signal.
	get_tree().change_scene_to_file.call_deferred(OVERWORLD_SCENE_PATH)


func _coerce_int_values(src: Dictionary) -> Dictionary:
	var out := {}
	for key in src:
		out[key] = int(src[key])
	return out
