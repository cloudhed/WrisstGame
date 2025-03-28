class_name Hand
extends VBoxContainer


func _ready() -> void:
	for child in get_children():
		var tile_ui := child as TileUI
		tile_ui.reparent_requested.connect(_on_tile_ui_reparent_requested)
		
		
func _on_tile_ui_reparent_requested(child: TileUI) -> void:
	child.reparent(self)
