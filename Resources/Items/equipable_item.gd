class_name EquipableItem
extends InventoryItem


@export_enum("weapon", "armor", "trinket") var equip_type: String = "weapon"
@export_enum("none", "1-handed", "2-handed") var hand_slot: String = "none"
@export var tile_bundle: TileBundle
