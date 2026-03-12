extends EnemyAction

@export var dud_tile: Tile
@export var dud_count := 1
@export_enum("discard", "draw_pile") var target_pile := "discard"


func is_performable() -> bool:
	return target != null and dud_tile != null and dud_count > 0 and ("stats" in target)


func perform_action() -> void:
	if not enemy or not target or not ("stats" in target):
		return

	var target_stats = target.stats
	if target_stats and target_stats.has_method("add_temporary_tiles_to_pile"):
		target_stats.add_temporary_tiles_to_pile(StringName(target_pile), dud_tile, dud_count)

	emit_combat_message(enemy, target, message_template, dud_count)
	if sound:
		SFXPlayer.play(sound)
	Events.enemy_action_completed.emit(enemy)