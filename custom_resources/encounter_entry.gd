class_name EncounterEntry
extends Resource

@export var enemy_stats: EnemyStats
@export_file("*.tres") var enemy_stats_path: String = ""
@export_range(0.0, 9999.0, 0.1) var weight: float = 1.0

# Optional fine-grained filters. Empty means "no restriction".
@export var allowed_biomes: PackedStringArray = PackedStringArray()
@export var allowed_time_periods: PackedStringArray = PackedStringArray() # e.g. ["Day"], ["Night"]

# If both are >= 0, interpreted as an inclusive hour window.
# Supports wrap-around windows (e.g. 22 -> 4).
@export_range(-1, 23, 1) var min_hour: int = -1
@export_range(-1, 23, 1) var max_hour: int = -1

# Flags are checked across quest/dialog/event/temp dictionaries.
@export var required_flags: PackedStringArray = PackedStringArray()
@export var blocked_flags: PackedStringArray = PackedStringArray()

@export var required_items: Array[InventoryItem] = []
@export var blocked_items: Array[InventoryItem] = []


func get_enemy_stats_path() -> String:
	if not enemy_stats_path.is_empty():
		return enemy_stats_path

	if enemy_stats != null:
		return enemy_stats.resource_path

	return ""


func get_enemy_stats() -> EnemyStats:
	if enemy_stats != null:
		return enemy_stats

	var path := get_enemy_stats_path()
	if path.is_empty():
		return null

	return load(path) as EnemyStats
