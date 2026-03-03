class_name EncounterTable
extends Resource

@export var biome_keys: PackedStringArray = PackedStringArray() # Empty => usable by any biome
@export_range(1, 9999, 1) var base_steps_min: int = 50
@export_range(1, 9999, 1) var base_steps_max: int = 100

@export_range(0.1, 10.0, 0.05) var day_steps_multiplier: float = 1.0
@export_range(0.1, 10.0, 0.05) var night_steps_multiplier: float = 1.0

@export var avoid_repeat_last_enemy: bool = true
@export var fallback_enemy: EnemyStats
@export var entries: Array[Resource] = []
