class_name NarrationBox
extends Control

@onready var panel: Panel = $Panel
@onready var label: RichTextLabel = $Panel/Text


const MAX_WIDTH: float = 600.0
const PADDING: float = 12.0

func _ready():
	update_box_size()


func set_text(text: String) -> void:
	label.bbcode_enabled = true
	label.clear()
	label.append_text(text)
	await get_tree().process_frame
	update_box_size()


func update_box_size() -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = MAX_WIDTH
	await get_tree().process_frame

	var content_width: float = label.get_content_width()
	var content_height: float = label.get_content_height()
	
	var padded_width: float = min(content_width, MAX_WIDTH) + PADDING * 2.0
	var padded_height: float = content_height + PADDING * 2.0

	panel.custom_minimum_size = Vector2(padded_width, padded_height)
	panel.size = Vector2.ZERO

	label.position = Vector2(PADDING, PADDING)
