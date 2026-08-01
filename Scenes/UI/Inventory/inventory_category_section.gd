class_name InventoryCategorySection
extends VBoxContainer

## One collapsible section of the inventory list: a clickable header and the
## item rows filed under it.
##
## Indentation is handled once by the margin container, so rows need no indent
## logic of their own.

signal expanded_changed(category_id: String, expanded: bool)

var category_id: String = ""

var _expanded: bool = true

@onready var header_button: Button = %HeaderButton
@onready var indent_margin: MarginContainer = %IndentMargin
@onready var row_container: VBoxContainer = %RowContainer


func _ready() -> void:
	header_button.pressed.connect(_on_header_pressed)
	_apply_expanded()


## Call before adding rows. Safe to call before the node is ready, matching the
## setup() convention used by InventoryItemSlot and logbook_entry_row.
func setup(p_category_id: String, p_expanded: bool) -> void:
	category_id = p_category_id
	_expanded = p_expanded
	if is_node_ready():
		_apply_expanded()


func add_row(row: Control) -> void:
	row_container.add_child(row)


func get_rows() -> Array[Node]:
	return row_container.get_children()


func _on_header_pressed() -> void:
	_expanded = not _expanded
	_apply_expanded()
	expanded_changed.emit(category_id, _expanded)


func _apply_expanded() -> void:
	indent_margin.visible = _expanded

	var tint := ItemCategory.color(category_id)
	header_button.text = "%s (%s)" % [
		ItemCategory.display_name(category_id),
		"-" if _expanded else "+",
	]
	header_button.add_theme_color_override("font_color", tint)
	header_button.add_theme_color_override("font_hover_color", tint.lightened(0.35))
	header_button.add_theme_color_override("font_pressed_color", tint.lightened(0.2))
	header_button.add_theme_color_override("font_focus_color", tint)
