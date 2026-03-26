class_name EncounterTable
extends Resource

@export var biome_keys: PackedStringArray = PackedStringArray() # Empty => usable by any biome
@export_range(1, 9999, 1) var base_steps_min: int = 50
@export_range(1, 9999, 1) var base_steps_max: int = 100

@export_range(0.1, 10.0, 0.05) var day_steps_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var night_steps_multiplier: float = 1.0

@export var avoid_repeat_last_enemy: bool = true
@export var fallback_enemy: EnemyStats
@export_file("*.tres") var fallback_enemy_path: String = ""
@export var entries: Array[Resource] = []


func get_fallback_enemy_path() -> String:
	if not fallback_enemy_path.is_empty():
		return fallback_enemy_path

	if fallback_enemy != null:
		return fallback_enemy.resource_path

	return ""


func get_fallback_enemy() -> EnemyStats:
	if fallback_enemy != null:
		return fallback_enemy

	var path := get_fallback_enemy_path()
	if path.is_empty():
		return null

	return load(path) as EnemyStats
