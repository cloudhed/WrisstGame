extends Control

## In-game debug overlay, toggled with the `debug_input` action.
##
## Every control in the right-hand column is declared as data here and built at
## runtime by `_build_controls()`, so adding a debug tool costs one row in a table
## instead of a hand-placed node with hand-picked pixel coordinates.
## `debug_panel.tscn` is a layout shell only, and should stay that way: containers
## own all positioning, which is what keeps the panel's parts from overlapping.

@onready var debug_ui: CanvasLayer = $DebugUI
@onready var debug_text: Label = %DebugText
@onready var flags_area: Control = %FlagsArea
@onready var flags_row: HBoxContainer = %FlagsRow
@onready var controls: VBoxContainer = %Controls

# ─────────────────────────────────────────────────────────────
# Button palette — new controls pick a mood rather than an RGB triplet.
const COLOR_HIGH := Color(1.0, 0.55, 0.0)
const COLOR_LOW := Color(0.0, 0.78, 0.78)
const COLOR_GOOD := Color(0.3, 0.9, 0.3)
const COLOR_INFO := Color(0.4, 0.7, 1.0)
const COLOR_DANGER := Color(0.9, 0.25, 0.25)
const COLOR_NEUTRAL := Color(0.8, 0.8, 0.8)

const ABILITIES := ["body", "mind", "soul"]

## Content-warning toggles: [GameState.content_settings key, button label].
const CONTENT_TOGGLES := [
	["feral", "Feral content"],
	["violence", "Violence content"],
]

## Roll override buttons: [AbilitySystem.roll_override mode, label, colour].
const ROLL_MODES := [
	["nat1", "Nat1", COLOR_DANGER],
	["rng", "RNG", COLOR_NEUTRAL],
	["nat20", "Nat20", COLOR_GOOD],
]

## Flag dump sections: [heading, GameState property, icon].
const FLAG_SECTIONS := [
	["Quest Flags", "quest_flags", "✅"],
	["Dialog Flags", "dialog_flags", "💬"],
	["Event Flags", "event_flags", "🎯"],
	["Knowledge Flags", "knowledge_flags", "📚"],
	["Sex Flags", "sex_flags", "🔥"],
	["Temp Flags", "temp_flags", "⏱️"],
]

## Roll override buttons, keyed by mode string.
var _roll_buttons: Dictionary = {}

## One flag column per FLAG_SECTIONS entry, in the same order.
var _flag_labels: Array[Label] = []

## Live-labelled toggles: [button, label_callable]. The callable is re-run on
## every refresh, so a toggle always reads its state straight from GameState.
var _toggles: Array[Array] = []


func _ready() -> void:
	debug_ui.visible = true
	_build_controls()
	if not GameState.combat_debug_settings_changed.is_connected(_refresh_debug_controls):
		GameState.combat_debug_settings_changed.connect(_refresh_debug_controls)
	_refresh_debug_controls()


# ─────────────────────────────────────────────────────────────
# Control construction
# ─────────────────────────────────────────────────────────────

func _build_controls() -> void:
	# --- Ability tier overrides ---
	for ability: String in ABILITIES:
		var row: HBoxContainer = _add_row(ability.capitalize() + ":")
		row.add_child(_make_button("Set High", _on_ability_override.bind(ability, "high"), COLOR_HIGH))
		row.add_child(_make_button("Set Low", _on_ability_override.bind(ability, "low"), COLOR_LOW))

	# --- Save / load ---
	var save_row: HBoxContainer = _add_row("Save:")
	save_row.add_child(_make_button("Save", SaveManager.save_game, COLOR_GOOD))
	save_row.add_child(_make_button("Load", SaveManager.load_game, COLOR_INFO))
	save_row.add_child(_make_button("New Game (wipe)", SaveManager.new_game, COLOR_DANGER))

	# --- Roll override ---
	var roll_row: HBoxContainer = _add_row("Roll:")
	for mode_data: Array in ROLL_MODES:
		var mode: String = mode_data[0]
		var btn: Button = _make_button(mode_data[1], _on_roll_override.bind(mode), mode_data[2])
		roll_row.add_child(btn)
		_roll_buttons[mode] = btn

	# --- Toggles ---
	_add_toggle(
		func() -> String: return "Deck reshuffle: %s" % GameState.get_debug_reshuffle_mode_label(),
		GameState.toggle_debug_immediate_discard_reshuffle
	)
	for entry: Array in CONTENT_TOGGLES:
		var key: String = entry[0]
		var label: String = entry[1]
		_add_toggle(
			func() -> String: return "%s: %s" % [label, "OFF" if GameState.content_settings[key] else "ON"],
			func() -> void: GameState.content_settings[key] = not GameState.content_settings[key]
		)


## Adds a labelled row to the control column and hands it back for buttons.
func _add_row(label_text: String) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	controls.add_child(row)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(48, 0)
	row.add_child(lbl)
	return row


## The single place a debug button is born.
func _make_button(text: String, on_pressed: Callable, color: Color) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.pressed.connect(on_pressed)
	btn.add_theme_color_override("font_color", color)
	btn.add_theme_color_override("font_hover_color", color.lightened(0.25))
	btn.add_theme_color_override("font_pressed_color", color.darkened(0.2))
	return btn


## Registers a toggle whose label is recomputed on every refresh. `on_pressed`
## runs before the refresh, so the new state is what gets drawn.
func _add_toggle(label_fn: Callable, on_pressed: Callable) -> void:
	var btn: Button = _make_button("", on_pressed, COLOR_NEUTRAL)
	btn.pressed.connect(_refresh_debug_controls)
	controls.add_child(btn)
	_toggles.append([btn, label_fn])


# ─────────────────────────────────────────────────────────────
# Actions
# ─────────────────────────────────────────────────────────────

func _on_roll_override(mode: String) -> void:
	AbilitySystem.roll_override = mode
	_refresh_roll_buttons()


func _on_ability_override(ability: String, tier: String) -> void:
	var current_high: String = ""
	var current_low: String = ""
	for a: String in ABILITIES:
		match AbilitySystem.get_tier(a):
			"high": current_high = a
			"low": current_low = a

	# Pick the best partner so the constraint (one high, one low) is always satisfied.
	var others: Array[String] = []
	for a: String in ABILITIES:
		if a != ability:
			others.append(a)

	if tier == "high":
		var new_low: String = current_low if (current_low != "" and current_low != ability) else others[0]
		AbilitySystem.assign_abilities(ability, new_low)
	else:
		var new_high: String = current_high if (current_high != "" and current_high != ability) else others[0]
		AbilitySystem.assign_abilities(new_high, ability)


# ─────────────────────────────────────────────────────────────
# Refresh
# ─────────────────────────────────────────────────────────────

func _refresh_debug_controls() -> void:
	if _toggles.is_empty():
		return  # GameState can emit before _build_controls() runs during startup
	for entry: Array in _toggles:
		var btn: Button = entry[0]
		var label_fn: Callable = entry[1]
		btn.text = label_fn.call()
	_refresh_roll_buttons()  # roll override can change when a save is loaded


func _refresh_roll_buttons() -> void:
	var active_mode: String = AbilitySystem.roll_override
	for mode: String in _roll_buttons:
		var btn: Button = _roll_buttons[mode]
		var is_active: bool = mode == active_mode
		btn.flat = not is_active
		btn.disabled = is_active


# ─────────────────────────────────────────────────────────────
# Input / visibility
# ─────────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if debug_ui.visible:
		_update_debug_info()


func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("escape") and not ev.is_echo():
		SaveManager.save_game()  # escape quits the game — autosave first
		get_tree().quit()
		return

	if ev.is_action_pressed("debug_input"):
		_toggle_debug_panel()


func _toggle_debug_panel() -> void:
	debug_ui.visible = not debug_ui.visible
	if debug_ui.visible:
		_refresh_debug_controls()
		_update_debug_info()


# ─────────────────────────────────────────────────────────────
# Readout
# ─────────────────────────────────────────────────────────────

func _update_debug_info() -> void:
	var core_info: String = ""
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

	debug_text.text = core_info
	_refresh_flag_labels()


## The flag dump is laid out newspaper-style: filled down one column, then
## wrapped into the next. A single stacked list outgrows the screen as soon as a
## save has real progress in it, so wrapping is what keeps the whole dump visible
## without the panel's other parts having to give up any room.
func _refresh_flag_labels() -> void:
	var lines: PackedStringArray = _build_flag_lines()
	var per_column: int = _flag_lines_per_column()
	var needed: int = maxi(1, ceili(float(lines.size()) / float(per_column)))
	_ensure_flag_columns(needed)

	for i: int in _flag_labels.size():
		var lbl: Label = _flag_labels[i]
		lbl.visible = i < needed
		if not lbl.visible:
			continue
		var start: int = i * per_column
		var end: int = mini(start + per_column, lines.size())
		lbl.text = "\n".join(lines.slice(start, end))


## Every flag line in display order, headings included, one entry per line.
func _build_flag_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for section: Array in FLAG_SECTIONS:
		lines.append("[%s]" % section[0])
		var flags: Dictionary = GameState.get(section[1])
		for key in flags:
			if flags[key]:
				lines.append("%s %s" % [section[2], key])
		lines.append("")
	return lines


## How many lines fit in one column, measured from the theme rather than guessed,
## so a font change can't quietly push the dump off the bottom again.
func _flag_lines_per_column() -> int:
	var font: Font = flags_row.get_theme_font("font", "Label")
	var font_size: int = flags_row.get_theme_font_size("font_size", "Label")
	var line_height: float = font.get_height(font_size) + flags_row.get_theme_constant("line_spacing", "Label")
	return maxi(1, int(flags_area.size.y / maxf(line_height, 1.0)))


## Columns are created on demand and then reused, since this runs every frame.
func _ensure_flag_columns(count: int) -> void:
	while _flag_labels.size() < count:
		var lbl: Label = Label.new()
		lbl.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		flags_row.add_child(lbl)
		_flag_labels.append(lbl)
