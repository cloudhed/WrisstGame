class_name EnemyStats
extends Stats

@export var species_id: StringName = &""
@export var ai: PackedScene
@export_file("*.json") var pre_combat_dialog_path: String = ""
@export_file("*.json") var post_combat_dialog_path: String = ""
@export var slide_deck: SlideDeck
@export var is_runnable: bool = true
#@export var dialog_scene_data: DialogSceneResource
#@export var post_combat_dialog: DialogSceneResource


func get_species_id() -> StringName:
	if not String(species_id).is_empty():
		return species_id

	if not resource_path.is_empty():
		var file := resource_path.get_file().get_basename().strip_edges().to_lower()
		if not file.is_empty():
			return StringName(file)

	if not player_name.is_empty():
		return StringName(player_name.strip_edges().to_lower().replace(" ", "_"))

	return StringName("unknown")
