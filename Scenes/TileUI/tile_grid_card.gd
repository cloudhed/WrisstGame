extends Control
class_name TileGridCard

@export var tile: Tile : set = _set_tile

@onready var background: TextureRect = $Background
@onready var icon: TextureRect = $Icon
@onready var amount_label: Label = $Amount

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if tile:
		_update_display()

func _set_tile(value: Tile) -> void:
	tile = value
	if is_node_ready():
		_update_display()

func _on_mouse_entered() -> void:
	if tile:
		var tip_icon: Texture = tile.tooltip_icon if tile.tooltip_icon else tile.icon
		Events.tile_tooltip_requested.emit(
			tip_icon,
			tile.get_formatted_tooltip_text(),
			tile.tooltip_source_label,
			global_position,
			size
		)


func _on_mouse_exited() -> void:
	Events.tooltip_hide_requested.emit()


func _update_display() -> void:
	background.texture = tile.background
	icon.texture = tile.icon
	amount_label.text = str(tile.effect_amount)
