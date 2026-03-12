class_name ApplyCombatStatusEffect
extends Effect

var status_id: StringName = &""
var status_data: Dictionary = {}


func execute(targets: Array[Node]) -> void:
	var applied := false
	for target in targets:
		if not target or not ("stats" in target):
			continue

		var target_stats = target.stats
		if target_stats == null or not target_stats.has_method("add_status"):
			continue

		target_stats.add_status(status_id, status_data.duplicate(true))
		applied = true

	if applied and sound:
		SFXPlayer.play(sound)