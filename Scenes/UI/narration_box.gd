class_name NarrationBox
extends Control

@export var max_width: float = 600.0
@export var padding: float = 12.0


func set_text(text: String) -> void:
	print("🧪 NarrationBox set_text():", text)

	var panel: Panel = get_node("Panel")
	var label: RichTextLabel = panel.get_node("Text")

	if label == null:
		push_error("❌ NarrationBox: 'Panel/Text' not found!")
		return

	label.bbcode_enabled = true
	label.clear()
	label.append_text(text)


	update_box_size(panel, label)


func update_box_size(panel: Panel, label: RichTextLabel) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = max_width

	# Make sure we're in the scene tree before trying to wait on layout updates
	if not is_inside_tree():
		await ready
	await get_tree().process_frame
	await get_tree().process_frame

	var content_width: float = label.get_content_width()
	var content_height: float = label.get_content_height()

	var padded_width: float = min(content_width, max_width) + padding * 2.0
	var padded_height: float = content_height + padding * 2.0

	var final_size := Vector2(padded_width, padded_height)
	panel.custom_minimum_size = final_size
	panel.size = final_size

	label.position = Vector2(padding, padding)
