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
	core_info += "💾 Player: %s (%s)\n" % [GameState.player_name, GameState.player_gender]
	core_info += "💰 Crowns: %d\n" % GameState.player_crowns
	core_info += "💰 Öre: %d\n" % GameState.player_ore
	core_info += "💰 Drots: %d\n" % GameState.player_drots

	core_info += "🗡️ Weapon: %s\n" % (GameState.equipped_weapon.resource_path if GameState.equipped_weapon else "None")
	core_info += "🛡️ Armor: %s\n" % (GameState.equipped_armor.resource_path if GameState.equipped_armor else "None")
	core_info += "🃏 Deck reshuffle: %s\n" % GameState.get_debug_reshuffle_mode_label()


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
