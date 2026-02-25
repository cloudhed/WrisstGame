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
	#print("🖥️ ACTUAL screen size reported:", get_viewport().get_window().size)
	is_visible = true
	hide_request_id += 1
	_kill_active_tween()

	tooltip_icon.texture = icon
	tooltip_text_label.text = text
	tooltip_source_label.text = source

	var screen_size: Vector2 = get_viewport().get_window().size
	var offset_x: float = 12.0
	var margin_buffer: float = 24.0

	# Default offset is to the right
	var offset: Vector2 = Vector2(tile_size.x + offset_x, 0)
	var tooltip_pos: Vector2 = tile_global_position + offset
	tooltip_pos.y += (tile_size.y * 0.5) - (size.y * 0.5)

	var tooltip_right_edge: float = tooltip_pos.x + size.x
	var screen_right_limit: float = screen_size.x - margin_buffer


	if tooltip_right_edge > screen_right_limit:
		offset.x = -size.x - offset_x
		tooltip_pos = tile_global_position + offset
		tooltip_pos.y += (tile_size.y * 0.5) - (size.y * 0.5)
#		print("Flipping to LEFT")
#	else:
#		print("Staying on RIGHT")

#	print("Final tooltip position:", tooltip_pos)
#	print("[END DEBUG]\n")

	global_position = tooltip_pos

	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(show)
	tween.tween_property(self, "modulate", Color.WHITE, fade_seconds)


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
