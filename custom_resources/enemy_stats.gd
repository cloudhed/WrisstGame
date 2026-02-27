class_name EnemyStats
extends Stats

@export var ai: PackedScene
@export_file("*.json") var pre_combat_dialog_path: String = ""
@export_file("*.json") var post_combat_dialog_path: String = ""
@export var slide_deck: SlideDeck
@export var is_runnable: bool = true
#@export var dialog_scene_data: DialogSceneResource
#@export var post_combat_dialog: DialogSceneResource
