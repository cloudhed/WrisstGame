class_name Tile
extends Resource

enum Type{ATTACK, DEFEND, POWER, DEBUFF, BUFF, FAIL}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

@export_group("Tile Attributes")
@export var id: String
@export var type: Type
@export var target: Target
@export var cost: int
#amount is added by me, not tutorial. might need to turn off if "amount" is happening elsewhere idk
@export var effect_amount: int = 0

@export_group("Tile Visuals")
@export var background: Texture
@export var icon: Texture
@export var tooltip_icon: Texture
@export var tooltip_source_label: String
@export_multiline var tooltip_text: String
@export_multiline var message_template := ""
@export var message_pool_resource: RandomMessagePool
@export_group("Tile SFX")
@export var sound: AudioStream
#@export var ui_sound: AudioStream

var source_stats: CharacterStats


func get_random_message_template() -> String:
	if message_pool_resource and message_pool_resource.messages.size() > 0:
		return message_pool_resource.messages[randi() % message_pool_resource.messages.size()]
	return message_template


func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY


func _get_targets(targets: Array[Node]) -> Array[Node]:
	if not targets:
		return []
	
	var tree := targets[0].get_tree()
	
	match target:
		Target.SELF:
			return tree.get_nodes_in_group("player")
		Target.ALL_ENEMIES:
			return tree.get_nodes_in_group("enemies")
		Target.EVERYONE:
			return tree.get_nodes_in_group("player") + tree.get_nodes_in_group("enemies")
		_:
			return []


func play(targets: Array[Node], char_stats: CharacterStats) -> void:
	if not char_stats.can_play_tile(self):
		print("[DEBUG] Tried to play a tile with not enough stamina! Tile cost:", cost, " | Current stamina:", char_stats.stamina)
		return
	
	Events.tile_played.emit(self)
	char_stats.stamina -= cost
	source_stats = char_stats

	if is_single_targeted():
		apply_effects(targets)
	else:
		apply_effects(_get_targets(targets))


func apply_effects(_targets: Array[Node]) -> void:
	pass


func get_display_name(entity: Node) -> String:
	if not entity:
		print(">>> get_display_name: entity is null")
		return "???"
	
	print(">>> get_display_name: ", entity)
	print(">>> Has 'stats'? ", "stats" in entity)
	
	if entity.has_method("get_stats"):
		var stats = entity.get_stats()
		print(">>> get_stats() returned: ", stats)
		if stats and "player_name" in stats:
			print(">>> player_name: ", stats.player_name)
			return stats.player_name
		else:
			print(">>> No 'player_name' in stats or stats is null")
	else:
		print(">>> Entity has no 'get_stats' method, using entity.name:", entity.name)

	return entity.name


func emit_combat_message(target: Node, amount: int) -> void:
	var template := get_random_message_template()
	if template.is_empty():
		return

	var source_name: String = source_stats.player_name
	var target_name := get_display_name(target)
	var message := template.format({
		"source_name": source_name,
		"target_name": target_name,
		"amount": amount
	})
	Events.emit_signal("combat_text_emitted", message)
