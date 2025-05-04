extends Node

const FADE_TIME: float = 1.5
const MIN_DB: float = -60.0
const MAX_DB: float = 0.0

var _layer_players: Dictionary = {}

func play_layer(tag: String, stream: AudioStream, fade_in: bool = true) -> void:
	if not stream or tag.is_empty():
		return

	# Fade out old layer if different stream
	if _layer_players.has(tag):
		var old_player: AudioStreamPlayer = _layer_players[tag]
		if old_player and old_player.playing:
			# If it's the same stream, no need to restart
			if old_player.stream == stream:
				print("🎧 Stream already playing on tag:", tag)
				return

			var tween: Tween = old_player.create_tween()
			tween.tween_property(old_player, "volume_db", MIN_DB, FADE_TIME)
			tween.tween_callback(func(): old_player.stop())
			_layer_players.erase(tag)  # Important!

	# Get a free player for the new stream
	var player: AudioStreamPlayer = _get_available_player()
	if player == null:
		print("❌ No free AudioStreamPlayers!")
		return

	player.stream = stream
	player.volume_db = MIN_DB if fade_in else MAX_DB
	player.play()

	if fade_in:
		var tween: Tween = player.create_tween()
		tween.tween_property(player, "volume_db", MAX_DB, FADE_TIME)

	_layer_players[tag] = player


@warning_ignore("shadowed_variable")
func stop_layer(tag: String, fade_out: bool = true) -> void:
	if not _layer_players.has(tag):
		return

	var player: AudioStreamPlayer = _layer_players[tag]
	if fade_out:
		var tween: Tween = player.create_tween()
		tween.tween_property(player, "volume_db", MIN_DB, FADE_TIME)
		tween.tween_callback(func(): player.stop())
	else:
		player.stop()

	_layer_players.erase(tag)


@warning_ignore("shadowed_variable")
func stop_all(fade_out: bool = true) -> void:
	for tag: String in _layer_players.keys():
		stop_layer(tag, fade_out)
	_layer_players.clear()


func _get_available_player() -> AudioStreamPlayer:
	for child in get_children():
		var player := child as AudioStreamPlayer
		if player and not player.playing:
			return player
	return null


# 🔊 Simple .play() for MusicPlayer
func play(stream: AudioStream, single: bool = true) -> void:
	if not stream:
		return

	if single:
		stop_all()

	var player: AudioStreamPlayer = _get_available_player()
	if player:
		player.stream = stream
		player.volume_db = MAX_DB
		player.play()


func stop() -> void:
	stop_all(true)


func fade_out(duration: float = 2.0) -> void:
	for player in get_children():
		if player is AudioStreamPlayer and player.playing:
			var tween: Tween = player.create_tween()
			tween.tween_property(player, "volume_db", -60.0, duration)
			tween.tween_callback(func(): player.stop())
