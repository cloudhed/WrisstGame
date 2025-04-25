extends Control
class_name TileGridCard

@export var tile: Tile : set = _set_tile

@onready var background: TextureRect = $Background
@onready var icon: TextureRect = $Icon
@onready var amount_label: Label = $Amount

func _ready():
	if tile:
		_update_display()

func _set_tile(value: Tile) -> void:
	tile = value
	if is_node_ready():
		_update_display()

func _update_display() -> void:
	background.texture = tile.background
	icon.texture = tile.icon
	amount_label.text = str(tile.effect_amount)
