class_name Tile
extends Resource

enum Type{ATTACK, DEFEND, POWER, DEBUFF, BUFF, FAIL}
enum Target {SELF, SINGLE_ENEMY, ALL_ENEMIES, EVERYONE}

@export_group("Tile Attributes")
@export var id: String
@export var type: Type
@export var target: Target
@export var cost: int
@export var amount: int

@export_group("Tile Visuals")
@export var background: Texture
@export var icon: Texture
@export_multiline var tooltip_text: String

func is_single_targeted() -> bool:
	return target == Target.SINGLE_ENEMY
