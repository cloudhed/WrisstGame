extends Control

@onready var debug_ui: CanvasLayer = $DebugUI
@onready var debug_text: Label = $DebugUI/DebugText
@onready var flags_text: Label = $DebugUI/FlagsText
@onready var reshuffle_toggle_button: Button = $DebugUI/ReshuffleToggleButton
@onready var feral_toggle_button: Button = $DebugUI/FeralToggleButton
@onready var violence_toggle_button: Button = $DebugUI/ViolenceToggleButton


func _ready():
	debug_ui.visible = true
	if GameState.has_signal("combat_debug_settings_changed") and not GameState.combat_debug_settings_changed.is_connected(_refresh_debug_controls):
		GameState.combat_debug_settings_changed.connect(_refresh_debug_controls)
	_refresh_debug_controls()
	_build_ability_buttons()


## Roll override toggle buttons — keyed by mode string.
var _roll_buttons: Dictionary = {}


func _build_ability_buttons() -> void:
	var container: VBoxContainer = VBoxContainer.new()
	container.position = Vector2(1602, 650)
	debug_ui.add_child(container)

	for ability: String in ["body", "mind", "soul"]:
		var row: HBoxContainer = HBoxContainer.new()
		container.add_child(row)

		var lbl: Label = Label.new()
		lbl.text = ability.capitalize() + ":"
		lbl.custom_minimum_size = Vector2(48, 0)
		row.add_child(lbl)

		for tier: String in ["high", "low"]:
			var btn: Button = Button.new()
			btn.text = "Set " + tier.capitalize()
			btn.pressed.connect(_on_ability_override.bind(ability, tier))
			var col: Color = Color(1.0, 0.55, 0.0) if tier == "high" else Color(0.0, 0.78, 0.78)
			btn.add_theme_color_override("font_color", col)
			btn.add_theme_color_override("font_hover_color", col.lightened(0.25))
			btn.add_theme_color_override("font_pressed_color", col.darkened(0.2))
			row.add_child(btn)

	# --- Roll override row ---
	var roll_row: HBoxContainer = HBoxContainer.new()
	container.add_child(roll_row)

	var roll_lbl: Label = Label.new()
	roll_lbl.text = "Roll:"
	roll_lbl.custom_minimum_size = Vector2(48, 0)
	roll_row.add_child(roll_lbl)

	var modes: Array[Array] = [
		["nat1",  "Nat1",  Color(0.9, 0.2, 0.2)],
		["rng",   "RNG",   Color(0.8, 0.8, 0.8)],
		["nat20", "Nat20", Color(0.2, 0.9, 0.2)],
	]
	for mode_data: Array in modes:
		var mode: String  = mode_data[0]
		var label: String = mode_data[1]
		var col: Color    = mode_data[2]
		var btn: Button = Button.new()
		btn.text = label
		btn.pressed.connect(_on_roll_override.bind(mode))
		btn.add_theme_color_override("font_color", col)
		btn.add_theme_color_override("font_hover_color", col.lightened(0.25))
		btn.add_theme_color_override("font_pressed_color", col.darkened(0.2))
		roll_row.add_child(btn)
		_roll_buttons[mode] = btn

	_refresh_roll_buttons()


func _on_roll_override(mode: String) -> void:
	AbilitySystem.roll_override = mode
	_refresh_roll_buttons()


func _refresh_roll_buttons() -> void:
	var active_mode: String = AbilitySystem.roll_override
	for mode: String in _roll_buttons:
		var btn: Button = _roll_buttons[mode]
		var is_active: bool = mode == active_mode
		btn.flat = not is_active
		btn.disabled = is_active


func _on_ability_override(ability: String, tier: String) -> void:
	var current_high: String = ""
	var current_low: String  = ""
	for a: String in ["body", "mind", "soul"]:
		match AbilitySystem.get_tier(a):
			"high": current_high = a
			"low":  current_low  = a

	# Pick the best partner so the constraint (one high, one low) is always satisfied.
	var others: Array[String] = []
	for a: String in ["body", "mind", "soul"]:
		if a != ability:
			others.append(a)

	if tier == "high":
		var new_low: String = current_low if (current_low != "" and current_low != ability) else others[0]
		AbilitySystem.assign_abilities(ability, new_low)
	else:
		var new_high: String = current_high if (current_high != "" and current_high != ability) else others[0]
		AbilitySystem.assign_abilities(new_high, ability)


func _process(delta):
	if debug_ui.visible:
		_update_debug_info()


func _unhandled_input(ev):
	if ev.is_action_pressed("escape") and not ev.is_echo():
		get_tree().quit()
		return

	# Toggle debug panel on debug_input action
	if ev.is_action_pressed("debug_input"):
		_toggle_debug_panel()


func _toggle_debug_panel():
	debug_ui.visible = not debug_ui.visible
	if debug_ui.visible:
		_refresh_debug_controls()
		_update_debug_info()
#		_refresh_inventory()
		pass


func _refresh_debug_controls() -> void:
	if not is_instance_valid(reshuffle_toggle_button):
		return
	reshuffle_toggle_button.text = "Deck reshuffle: %s" % GameState.get_debug_reshuffle_mode_label()
	feral_toggle_button.text = "Feral content: %s" % ("OFF" if GameState.content_settings["feral"] else "ON")
	violence_toggle_button.text = "Violence content: %s" % ("OFF" if GameState.content_settings["violence"] else "ON")


func _update_debug_info():
	var core_info = ""
	core_info += "%s %s\n" % ["🌙" if GameState.is_night else "☀️", "Night" if GameState.is_night else "Day"]
	core_info += "💾 Player: %s (%s)\n" % [GameState.player_name, GameState.player_gender]
	core_info += "💰 Crowns: %d\n" % GameState.player_crowns
	core_info += "💰 Öre: %d\n" % GameState.player_ore
	core_info += "💰 Drots: %d\n" % GameState.player_drots

	core_info += "🗡️ Weapon: %s\n" % (GameState.equipped_weapon.resource_path if GameState.equipped_weapon else "None")
	core_info += "🛡️ Armor: %s\n" % (GameState.equipped_armor.resource_path if GameState.equipped_armor else "None")
	core_info += "🃏 Deck reshuffle: %s\n" % GameState.get_debug_reshuffle_mode_label()


	core_info += "🎲 Body: %s(%d)  Mind: %s(%d)  Soul: %s(%d)\n" % [
		AbilitySystem.get_tier("body"), AbilitySystem.get_score("body"),
		AbilitySystem.get_tier("mind"), AbilitySystem.get_score("mind"),
		AbilitySystem.get_tier("soul"), AbilitySystem.get_score("soul"),
	]
	if not AbilitySystem.last_roll.is_empty():
		var r: Dictionary = AbilitySystem.last_roll
		var outcome: String = "NAT 20!" if r["nat_20"] else ("HIT" if r["success"] else "MISS")
		core_info += "   └ Last: d20:%d + %s:%d + bonus:%d = %d vs DC%d → %s\n" % [
			r["roll"], r["ability"], r["score"], r["bonus"], r["total"], r["dc"], outcome,
		]
		if not r["bonus_parts"].is_empty():
			core_info += "     Bonuses: %s\n" % ", ".join(r["bonus_parts"])
	core_info += "🎒 Inventory size: %d\n" % GameState.player_inventory.size()
	core_info += "🤍 iReputation entries: %d\n" % GameState.npc_reputation.size()

	var combat := get_tree().get_current_scene() as Combat
	if combat and combat.player and combat.player.stats and combat.player.stats.has_method("get_debug_status_summary"):
		core_info += "☠️ Combat statuses: %s\n" % combat.player.stats.get_debug_status_summary()

	debug_ui.get_node("DebugText").text = core_info

	# FLAG DUMP
	var flag_text = "[Quest Flags]\n"
	for key in GameState.quest_flags.keys():
		if GameState.quest_flags[key]:
			flag_text += "✅ %s\n" % key

	flag_text += "\n[Dialog Flags]\n"
	for key in GameState.dialog_flags.keys():
		if GameState.dialog_flags[key]:
			flag_text += "💬 %s\n" % key

	flag_text += "\n[Event Flags]\n"
	for key in GameState.event_flags.keys():
		if GameState.event_flags[key]:
			flag_text += "🎯 %s\n" % key

	flag_text += "\n[Knowledge Flags]\n"
	for key in GameState.knowledge_flags.keys():
		if GameState.knowledge_flags[key]:
			flag_text += "📚 %s\n" % key

	flag_text += "\n[Sex Flags]\n"
	for key in GameState.sex_flags.keys():
		if GameState.sex_flags[key]:
			flag_text += "🔥 %s\n" % key

	flag_text += "\n[Temp Flags]\n"
	for key in GameState.temp_flags.keys():
		if GameState.temp_flags[key]:
			flag_text += "⏱️ %s\n" % key

	debug_ui.get_node("FlagsText").text = flag_text


func _on_reshuffle_toggle_button_pressed() -> void:
	GameState.toggle_debug_immediate_discard_reshuffle()
	_refresh_debug_controls()
	_update_debug_info()


func _on_feral_toggle_button_pressed() -> void:
	GameState.content_settings["feral"] = not GameState.content_settings["feral"]
	_refresh_debug_controls()


func _on_violence_toggle_button_pressed() -> void:
	GameState.content_settings["violence"] = not GameState.content_settings["violence"]
	_refresh_debug_controls()
