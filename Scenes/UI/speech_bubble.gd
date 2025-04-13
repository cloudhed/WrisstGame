class_name SpeechBubble
extends Control

@export var max_width: float = 500.0
@export var padding: float = 2.0

@export var gust_range_x: float = 30.0
@export var gust_range_y: float = 10.0
@export var gust_time: float = 0.4

@export var drift_range_x: float = 12.0
@export var drift_range_y: float = 6.0
@export var drift_time: float = 4.2


func set_text(
	text: String,
	text_color: Color = Color.WHITE,
	bubble_color: Color = Color.DIM_GRAY,
	font_override: Font = null
) -> void:

	var panel: Panel = get_node("BubbleWrapper/Panel")
	var label: RichTextLabel = panel.get_node("BubbleText")

	if panel == null or label == null:
		push_error("❌ SpeechBubble: Missing Panel or Label node!")
		return

	label.bbcode_enabled = true
	label.clear()

	if font_override:
		label.add_theme_font_override("normal_font", font_override)

	label.push_color(text_color)
	label.append_text(text)
	label.pop()

	# 🧠 Wait for scene tree before layout
	if not is_inside_tree():
		await ready

	# Wait 2 frames to allow RichTextLabel to update its layout
	await get_tree().process_frame
	await get_tree().process_frame

	# Layout and animation
	update_box_size(panel, label)
	animate_floaty_drift(panel)

	# 🟦 Apply bubble color
	if panel.has_theme_stylebox("panel"):
		var stylebox := panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		stylebox.bg_color = bubble_color
		panel.add_theme_stylebox_override("panel", stylebox)


func update_box_size(panel: Panel, label: RichTextLabel) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = max_width

	# Force layout updates
	await get_tree().process_frame
	await get_tree().process_frame

	# Try both width and height
	var content_width: float = label.get_content_width()
	var content_height: float = label.get_content_height()

	var padded_width: float = min(content_width, max_width) + padding * 2.0
	var padded_height: float = content_height + padding * 2.0

	var final_size = Vector2(padded_width, padded_height)

	# Apply to panel
	panel.custom_minimum_size = final_size
	panel.size = final_size

	# Apply label offset
	label.position = Vector2(padding, padding)

	# Force resize up the chain
	var wrapper = get_node("BubbleWrapper") if has_node("BubbleWrapper") else null
	if wrapper:
		wrapper.queue_sort()
		wrapper.queue_redraw()


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
