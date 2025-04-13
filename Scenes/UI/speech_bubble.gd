extends Control
class_name SpeechBubble

@onready var panel: Panel = $Panel
@onready var label: RichTextLabel = $Panel/BubbleText


const MAX_WIDTH: float = 500.0
const PADDING: float = 2.0

func _ready():
	print("📦 Label type is: ", label.get_class())
	update_box_size()


func set_text(text: String, text_color: Color = Color.WHITE, bubble_color: Color = Color.DIM_GRAY, font_override: Font = null) -> void:
	label.bbcode_enabled = true
	label.clear()

	# Font override (optional)
	if font_override:
		label.add_theme_font_override("normal_font", font_override)

	# Text color override
	label.push_color(text_color)
	label.append_text(text)
	label.pop()

	await get_tree().process_frame

	# Bubble background color override
	if panel.has_theme_stylebox("panel"):
		var stylebox = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		stylebox.bg_color = bubble_color
		panel.add_theme_stylebox_override("panel", stylebox)

	update_box_size()
	animate_floaty_drift()


func animate_floaty_drift():
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var original_position: Vector2 = panel.position

	# Step 1: Initial gust (stronger & fast)
	var gust_offset := Vector2(randf_range(-30.0, 30.0), randf_range(-10.0, 10.0))
	var gust_time := 0.4
	tween.tween_property(panel, "position", original_position + gust_offset, gust_time)

	# Step 2: Gentle drift (starts *after* gust finishes)
	var drift_offset := Vector2(randf_range(-12.0, 12.0), randf_range(-6.0, 6.0))
	var drift_time := 4.2
	tween.tween_property(panel, "position", original_position + drift_offset, drift_time)


func update_box_size() -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART  # ✅ one long line
	label.custom_minimum_size.x = MAX_WIDTH
	await get_tree().process_frame

	var content_width: float = label.get_content_width()
	var content_height: float = label.get_content_height()
	
	var padded_width: float = min(content_width, MAX_WIDTH) + PADDING * 2.0
	var padded_height: float = content_height + PADDING * 2.0

	panel.custom_minimum_size = Vector2(padded_width, padded_height)
	panel.size = Vector2.ZERO

	label.position = Vector2(PADDING, PADDING)
