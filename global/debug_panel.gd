extends Control

@onready var debug_ui: CanvasLayer = $DebugUI
@onready var debug_text: Label = $DebugUI/DebugText
@onready var flags_text: Label = $DebugUI/FlagsText


func _ready():
	debug_ui.visible = false


func _process(delta):
	if debug_ui.visible:
		_update_debug_info()


func _unhandled_input(ev):
	# Toggle inventory on “I” press (make sure you set ui_inventory in InputMap)
	if ev.is_action_pressed("debug_input"):
		_toggle_debug_panel()


func _toggle_debug_panel():
	debug_ui.visible = not debug_ui.visible
	if debug_ui.visible:
		_update_debug_info()
#		_refresh_inventory()
		pass


func _update_debug_info():
	var core_info = ""
	core_info += "💾 Player: %s (%s)\n" % [GameState.player_name, GameState.player_gender]
	core_info += "💰 Crowns: %d\n" % GameState.player_crowns
	core_info += "💰 Öre: %d\n" % GameState.player_ore
	core_info += "💰 Drots: %d\n" % GameState.player_drots

	core_info += "🗡️ Weapon: %s\n" % (GameState.equipped_weapon.resource_path if GameState.equipped_weapon else "None")
	core_info += "🛡️ Armor: %s\n" % (GameState.equipped_armor.resource_path if GameState.equipped_armor else "None")


	core_info += "🎒 Inventory size: %d\n" % GameState.player_inventory.size()
	core_info += "🧑 Reputation entries: %d\n" % GameState.npc_reputation.size()

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
	
	flag_text += "\n[Temp Flags]\n"
	for key in GameState.temp_flags.keys():
		if GameState.temp_flags[key]:
			flag_text += "⏱️ %s\n" % key

	debug_ui.get_node("FlagsText").text = flag_text
