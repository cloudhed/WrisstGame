# scene_manager.gd
extends Node

var _previous_scene: PackedScene = null
var enemy_resource: Resource = null
const combat_scene = preload("res://Scenes/combat.tscn")
#@export var combat_scene: PackedScene  # 👈 set this in editor!


func start_combat(enemy_res: Resource, parent_node: Node) -> Combat:
	enemy_resource = enemy_res

	var combat_instance = combat_scene.instantiate()
	if combat_instance is Combat:
		combat_instance.char_stats = GameState.player_stats
	else:
		push_error("❌ SceneManager: combat_scene is not a Combat scene.")
		return null  # ✅ Early exit returns null

	# ✅ NEW: Overlay mode
	if parent_node:
		parent_node.add_child(combat_instance)
		print("✅ Combat added as child to parent (overlay mode).")
	else:
		get_tree().root.add_child(combat_instance)
		print("⚠️ No parent given, combat added to root.")

	return combat_instance  # ✅ Add this line!

	
	

func return_to_previous_scene() -> void:
	# We can remove this logic OR keep as fallback
	if _previous_scene:
		get_tree().change_scene_to_packed(_previous_scene)
	else:
		get_tree().change_scene_to_file("res://overworldNav.tscn")


#func start_combat(enemy_res: Resource, return_scene: PackedScene) -> void:
	#enemy_resource = enemy_res
	#_previous_scene = return_scene
#
	#if not combat_scene:
		#push_error("❌ SceneManager: combat_scene not set!")
		#return
#
	#var combat_instance = combat_scene.instantiate()
	#if combat_instance is Combat:
		## ✅ THIS is what you need:
		#combat_instance.char_stats = GameState.player_stats
	#else:
		#push_error("❌ SceneManager: combat_scene is not a Combat scene.")
		#return
#
	## ✅ manual scene swap to allow data assignment
	#var old_scene = get_tree().current_scene
	#get_tree().root.add_child(combat_instance)
	#get_tree().current_scene = combat_instance
#
	#if old_scene:
		#old_scene.queue_free()
#
#
#func return_to_previous_scene() -> void:
	#if _previous_scene:
		#get_tree().change_scene_to_packed(_previous_scene)
	#else:
		#print("⚠️ No previous scene set, fallback to world or main menu.")
		## Replace this with your actual world scene
		#get_tree().change_scene_to_file("res://overworldNav.tscn")
