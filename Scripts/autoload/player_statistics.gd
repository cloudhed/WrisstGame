class_name PlayerStatistics
extends Resource

signal stats_changed

const SCHEMA_VERSION := 1

var schema_version: int = SCHEMA_VERSION
var global: Dictionary = {
	"encounters_total": 0,
	"wins_total": 0,
	"losses_total": 0,
	"sex_total": 0,
}
var species: Dictionary = {}


func ensure_species(species_id: StringName) -> Dictionary:
	var key := String(species_id)
	if key.is_empty():
		key = "unknown"

	if not species.has(key):
		species[key] = {
			"met": 0,
			"wins": 0,
			"losses": 0,
			"sex": 0,
			"last_seen_unix": 0,
		}

	return species[key]


func increment_species(species_id: StringName, stat_key: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	var entry := ensure_species(species_id)
	entry[stat_key] = int(entry.get(stat_key, 0)) + amount
	entry["last_seen_unix"] = Time.get_unix_time_from_system()
	stats_changed.emit()


func increment_global(stat_key: String, amount: int = 1) -> void:
	if amount <= 0:
		return

	global[stat_key] = int(global.get(stat_key, 0)) + amount
	stats_changed.emit()


func record_encounter(species_id: StringName) -> void:
	increment_species(species_id, "met")
	increment_global("encounters_total")


func record_win(species_id: StringName) -> void:
	increment_species(species_id, "wins")
	increment_global("wins_total")


func record_loss(species_id: StringName) -> void:
	increment_species(species_id, "losses")
	increment_global("losses_total")


func record_sex(species_id: StringName) -> void:
	increment_species(species_id, "sex")
	increment_global("sex_total")


func get_species_stat(species_id: StringName, stat_key: String, default_value: int = 0) -> int:
	var key := String(species_id)
	if key.is_empty() or not species.has(key):
		return default_value

	return int(species[key].get(stat_key, default_value))


func to_dict() -> Dictionary:
	return {
		"schema_version": schema_version,
		"global": global.duplicate(true),
		"species": species.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	schema_version = int(data.get("schema_version", SCHEMA_VERSION))
	global = data.get("global", {}).duplicate(true)
	species = data.get("species", {}).duplicate(true)
	stats_changed.emit()