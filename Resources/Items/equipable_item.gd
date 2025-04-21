class_name EquipableItem
extends Resource

@export var name: String = "Unnamed"
@export var icon: Texture
@export_multiline var description: String
@export_enum("weapon", "armor", "trinket") var item_type: String = "weapon"
@export_enum("none", "1-handed", "2-handed") var hand_slot: String = "none"
@export var tile_bundle: TileBundle
@export var hidden_from_inventory: bool = false
