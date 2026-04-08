class_name LogbookEntryRow
extends HBoxContainer
## A single row in the logbook. Handles parent vs child visual state,
## active vs completed styling, and the gold flash on first appearance.

var entry_id: String = ""

@onready var indent_spacer: Control = %IndentSpacer
@onready var connector_label: Label = %ConnectorLabel
@onready var entry_label: RichTextLabel = %EntryLabel

# Colors
const COLOR_ACTIVE := Color(0.94, 0.9, 0.78)        # warm cream
const COLOR_ACTIVE_CHILD := Color(0.82, 0.78, 0.68)  # slightly dimmer
const COLOR_COMPLETE := Color(0.5, 0.47, 0.42)       # muted grey
const COLOR_FLASH := Color(0.95, 0.82, 0.35)         # gold highlight


func setup(id: String, is_child: bool, status: String, flash: bool = false) -> void:
	entry_id = id

	var data: Dictionary = LogbookData.get_entry(id)
	var display_text: String = data.get("text", id)

	# Indentation and connector for child entries
	indent_spacer.custom_minimum_size.x = 24.0 if is_child else 0.0
	connector_label.text = "+-  " if is_child else ""

	# Build BBCode based on status
	var is_complete := (status == "complete")
	var color: Color
	if is_complete:
		color = COLOR_COMPLETE
	elif is_child:
		color = COLOR_ACTIVE_CHILD
	else:
		color = COLOR_ACTIVE

	var hex := "#" + color.to_html(false)

	if is_complete:
		entry_label.text = "[color=%s][s]%s[/s][/color]" % [hex, display_text]
	else:
		entry_label.text = "[color=%s]%s[/color]" % [hex, display_text]

	connector_label.add_theme_color_override("font_color", color)

	# Gold flash for newly added entries
	if flash and not is_complete:
		_play_flash()


func _play_flash() -> void:
	if not is_node_ready():
		await ready
	entry_label.modulate = COLOR_FLASH
	var tween := create_tween()
	tween.tween_property(entry_label, "modulate", Color.WHITE, 0.8) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
