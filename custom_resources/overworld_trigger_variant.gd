class_name OverworldTriggerVariant
extends Resource

@export var variant_id: StringName
@export var prompt_override: String = ""

# If empty => no restriction.
@export var allowed_time_periods: PackedStringArray = PackedStringArray() # e.g. ["Day"], ["Night"]
@export_range(-1, 23, 1) var min_hour: int = -1
@export_range(-1, 23, 1) var max_hour: int = -1

@export var required_flags: PackedStringArray = PackedStringArray()
@export var blocked_flags: PackedStringArray = PackedStringArray()

@export var required_items: Array[InventoryItem] = []
@export var blocked_items: Array[InventoryItem] = []

@export var dialog_scene: DialogSceneResource
@export var dialog_scene_selector_key: String = ""
