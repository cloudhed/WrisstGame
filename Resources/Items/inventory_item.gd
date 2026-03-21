class_name InventoryItem
extends Resource

@export var name: String = "Unnamed"
@export var icon: Texture
@export_multiline var description: String
@export_enum("equipable", "consumable", "quest", "key", "misc") var item_type: String = "quest"
@export var is_stackable: bool = false
@export var max_stack: int = 99
@export var hidden_from_inventory: bool = false
@export var sell_price_ore: int = 0
@export var sell_price_crowns: int = 0
@export var sell_price_drots: int = 0

func is_sellable() -> bool:
	return sell_price_ore > 0 or sell_price_crowns > 0 or sell_price_drots > 0
