class_name NarrationBox
extends Control

@export var max_width: float = 800.0
@export var padding: float = 12.0

@export var gust_range_x: float = 6.0
@export var gust_range_y: float = 3.0
@export var gust_time: float = 0.5

@export var drift_range_x: float = 0.0
@export var drift_range_y: float = 0.0
@export var drift_time: float = 2


func set_text(text: String) -> void:
	visible = false  # Hide while sizing
#	print("🧪 NarrationBox set_text():", text)

	var panel: Panel = get_node("BoxWrapper/Panel")
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
	
	self.custom_minimum_size = final_size
	self.size = final_size

	label.position = Vector2(padding, padding)
	visible = true
	
		# Force resize up the chain
	var wrapper = get_node("BoxWrapper") if has_node("BoxWrapper") else null
	if wrapper:
		wrapper.queue_sort()
		wrapper.queue_redraw()
	
	animate_floaty_drift(panel)


func animate_floaty_drift(panel: Panel) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var original_position: Vector2 = panel.position

	var gust_offset: Vector2 = Vector2(
		randf_range(-gust_range_x, gust_range_x),
		randf_range(-gust_range_y, gust_range_y)
	)
	tween.tween_property(panel, "position", original_position + gust_offset, gust_time)

	var drift_offset: Vector2 = Vector2(
		randf_range(-drift_range_x, drift_range_x),
		randf_range(-drift_range_y, drift_range_y)
	)
	tween.tween_property(panel, "position", original_position + drift_offset, drift_time)
