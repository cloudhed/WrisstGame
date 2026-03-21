class_name Tooltip
extends PanelContainer

@export var fade_seconds := 0.1

@onready var tooltip_icon: TextureRect = %TooltipIcon
@onready var tooltip_text_label: RichTextLabel = %TooltipText
@onready var tooltip_source_label: Label = %TooltipLabel

var tween: Tween
var is_visible := false
var hide_request_id: int = 0


func _kill_active_tween() -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = null

func _ready() -> void:
	show()
	Events.tile_tooltip_requested.connect(show_tooltip)
	Events.tooltip_hide_requested.connect(hide_tooltip)
	modulate = Color.TRANSPARENT
	hide()


func show_tooltip(icon: Texture, text: String, source: String, tile_global_position: Vector2, tile_size: Vector2) -> void:
	is_visible = true
	hide_request_id += 1
	_kill_active_tween()

	tooltip_icon.texture = icon
	tooltip_text_label.text = text
	tooltip_source_label.text = source

	# First reset establishes the correct WIDTH so layout can run at the right constraints.
	# On first show, RichTextLabel width is 1px (never laid out), so get_combined_minimum_size()
	# returns a huge height. We accept this temporarily and let the layout settle.
	reset_size()
	tooltip_text_label.reset_size()
	show()

	# Wait one frame for the deferred layout update to run and reflow RichTextLabel at correct width
	await get_tree().process_frame
	if not is_visible:
		return

	# Second reset: the layout has now settled at the correct width, so get_combined_minimum_size()
	# returns the true minimum height. The PanelContainer is in Position mode (layout_mode=0) with
	# a plain Control parent — it will NOT auto-shrink from the first reset's oversized value.
	# Calling reset_size() again here is the only way to correct it.
	reset_size()

	_position_tooltip(tile_global_position, tile_size)

	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)


func _position_tooltip(tile_global_position: Vector2, tile_size: Vector2) -> void:
	var screen_size: Vector2 = get_viewport().get_window().size
	var offset_x: float = 12.0
	var margin_buffer: float = 24.0

	# Default: position to the right of the hovered element
	var offset: Vector2 = Vector2(tile_size.x + offset_x, 0)
	var tooltip_pos: Vector2 = tile_global_position + offset
	tooltip_pos.y += (tile_size.y * 0.5) - (size.y * 0.5)

	# Flip to left side if it would go off-screen
	var tooltip_right_edge: float = tooltip_pos.x + size.x
	var screen_right_limit: float = screen_size.x - margin_buffer
	if tooltip_right_edge > screen_right_limit:
		offset.x = -size.x - offset_x
		tooltip_pos = tile_global_position + offset
		tooltip_pos.y += (tile_size.y * 0.5) - (size.y * 0.5)

	# Clamp vertically so tooltip stays on screen
	tooltip_pos.y = clampf(tooltip_pos.y, margin_buffer, screen_size.y - size.y - margin_buffer)

	global_position = tooltip_pos


func hide_tooltip() -> void:
	is_visible = false
	hide_request_id += 1
	var request_id := hide_request_id
	_kill_active_tween()
		
	get_tree().create_timer(fade_seconds, false).timeout.connect(func(): hide_animation(request_id))
	
	
func hide_animation(request_id: int = -1) -> void:
	if request_id != -1 and request_id != hide_request_id:
		return

	if is_visible:
		return

	_kill_active_tween()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
	tween.tween_callback(hide)
# NEW CHATGPT HIDING THINGS
#	if tween:
#		tween.kill()
		
#	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
#	if not is_visible:
#		tween.tween_property(self, "modulate", Color.TRANSPARENT, fade_seconds)
	
#	tween.tween_callback(hide)
