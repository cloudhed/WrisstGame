class_name DialogLogicHandler
extends Node

# Reference to GameState for condition checks
var game_state: Node

func _init():
	game_state = GameState  # Assume GameState is autoloaded

# 🧠 Check flags and return the next dialog ID (as String)
func check_flags(entry: Dictionary, _unused_flag_dict: Dictionary) -> String:
	if not entry.has("check_flags"):
		push_error("❌ Logic entry missing 'check_flags'")
		return ""

	var logic: Dictionary = entry["check_flags"]
	print("🔍 Checking flags:", logic)

	var flags_to_check: Array[String] = []
	for flag in logic.get("flags", []):
		if typeof(flag) == TYPE_STRING:
			flags_to_check.append(flag)

	var all_flags_set := true
	for flag_name in flags_to_check:
		var is_set: bool = (
			GameState.quest_flags.get(flag_name, false)
			or GameState.dialog_flags.get(flag_name, false)
			or GameState.event_flags.get(flag_name, false)
		)
		print("🔸 Flag '%s' set? %s" % [flag_name, is_set])
		if not is_set:
			all_flags_set = false
			break

	var target_id: String = str(logic.get("on_success", "")) if all_flags_set else str(logic.get("on_fail", ""))
	print("➡️ Next target ID:", target_id)
	return target_id


# 🧬 Gender/Name condition check
func check_stat_condition(entry: Dictionary) -> String:
	if not entry.has("condition"):
		push_error("❌ Logic entry missing 'condition'")
		return ""

	var condition: Dictionary = entry["condition"]
	var stat: String = condition.get("stat", "")
	var expected_value: Variant = condition.get("is", null)
	var on_success: String = str(condition.get("on_success", ""))
	var on_fail: String = str(condition.get("on_fail", ""))

	if stat.is_empty() or expected_value == null:
		push_error("❌ Missing 'stat' or 'is' in condition")
		return on_fail

	# Check supported stats
	var actual_value: Variant = null
	match stat:
		"player_gender":
			actual_value = game_state.player_gender
		"player_name":
			actual_value = game_state.player_name
		_:
			push_error("❌ Unsupported stat in condition: %s" % stat)
			return on_fail

	return on_success if actual_value == expected_value else on_fail


# 💰 Check currency conditions and return next dialog ID (as String)
func check_condition(entry: Dictionary) -> String:
	if not entry.has("condition"):
		push_error("❌ Logic entry missing 'condition'")
		return ""

	var condition: Dictionary = entry["condition"]
	var currency: String = str(condition.get("currency", "ore"))
	var amount: int = int(condition.get("amount", 0))
	var on_success: String = str(condition.get("on_success", ""))
	var on_fail: String = str(condition.get("on_fail", ""))
	var deduct: bool = condition.get("deduct", false)

	var has_enough: bool = false

	match currency:
		"ore":
			has_enough = game_state.player_ore >= amount
		"crowns":
			has_enough = game_state.player_crowns >= amount
		"drots":
			has_enough = game_state.player_drots >= amount
		_:
			print("❌ Unknown currency type:", currency)

	if has_enough and deduct:
		match currency:
			"ore":
				game_state.remove_ore(amount)
			"crowns":
				game_state.remove_crowns(amount)
			"drots":
				game_state.remove_drots(amount)

	return on_success if has_enough else on_fail
