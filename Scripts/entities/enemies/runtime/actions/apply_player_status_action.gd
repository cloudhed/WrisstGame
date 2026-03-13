extends EnemyAction

const APPLY_COMBAT_STATUS_EFFECT_SCRIPT := preload("res://Scripts/combat/effects/apply_combat_status_effect.gd")

@export var status_id: StringName = &"poison"
@export var status_turns := 1
@export var status_value := 1
@export var use_draw_amount_field := false


func is_performable() -> bool:
	if not target or not ("stats" in target):
		return false

	var target_stats = target.stats
	if target_stats == null or not target_stats.has_method("has_status"):
		return false

	return not target_stats.has_status(status_id)


func perform_action() -> void:
	if not enemy or not target:
		return

	var status_effect = APPLY_COMBAT_STATUS_EFFECT_SCRIPT.new()
	status_effect.sound = sound
	status_effect.status_id = status_id
	status_effect.status_data = _build_status_data()
	status_effect.execute([target])
	emit_combat_message(enemy, target, message_template, status_value)
	Events.enemy_action_completed.emit(enemy)


func _build_status_data() -> Dictionary:
	var data := {
		"remaining_turns": status_turns
	}

	match String(status_id):
		"poison":
			data["damage"] = status_value
		"rattled":
			data["draw_amount"] = status_value if use_draw_amount_field else 2
			data["remaining_turns"] = max(status_turns, 2)
		_:
			data["value"] = status_value

	return data