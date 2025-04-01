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
#@export var amount: int

@export_group("Tile Visuals")
@export var background: Texture
@export var icon: Texture
@export_multiline var tooltip_text: String

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
	Events.tile_played.emit(self)
	char_stats.stamina -= cost
	
	if is_single_targeted():
		apply_effects(targets)
	else:
		apply_effects(_get_targets(targets))


func apply_effects(_targets: Array[Node]) -> void:
	pass
