class_name LogbookScreen
extends Panel
## The logbook UI panel. Shows active and completed task entries
## with parent/child hierarchy. Opened via keybind (L).

signal logbook_closed

const ENTRY_ROW_PATH := "res://Scenes/UI/Logbook/logbook_entry_row.tscn"
var _entry_row_scene: PackedScene = null

@onready var entry_list: VBoxContainer = %EntryList
@onready var empty_label: Label = %EmptyLabel
@onready var close_button: Button = %CloseButton

# Track which entries we've already shown, so we can flash new ones
var _known_entries: Dictionary = {}


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_on_close_pressed)
	GameState.logbook_updated.connect(_on_logbook_updated)


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false
	logbook_closed.emit()


func _on_close_pressed() -> void:
	close()


func _on_logbook_updated(_entry_id: String) -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	# Clear existing rows
	for child in entry_list.get_children():
		child.queue_free()

	if _entry_row_scene == null:
		_entry_row_scene = load(ENTRY_ROW_PATH) as PackedScene
		if _entry_row_scene == null:
			push_error("Failed to load logbook entry row scene: " + ENTRY_ROW_PATH)
			return

	var ordered_ids: Array[String] = LogbookData.get_ordered_ids()
	var has_entries := false

	for id in ordered_ids:
		var status: String = GameState.get_logbook_status(id)
		if status.is_empty():
			continue  # not yet added to game

		has_entries = true
		var data: Dictionary = LogbookData.get_entry(id)
		var parent_id: String = data.get("parent", "")
		var is_child := not parent_id.is_empty()

		# Flash if this is a newly seen entry
		var should_flash := not _known_entries.has(id)
		_known_entries[id] = true

		var row: LogbookEntryRow = _entry_row_scene.instantiate() as LogbookEntryRow
		entry_list.add_child(row)
		row.setup(id, is_child, status, should_flash)

	empty_label.visible = not has_entries
