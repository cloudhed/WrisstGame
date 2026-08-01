class_name InventoryItem
extends Resource

@export var name: String = "Unnamed"
@export var icon: Texture
@export_multiline var description: String
## Drives which section the item appears under in the inventory list. See
## ItemCategory.classify(); equipment is keyed off its slot instead, so
## "equipable" items never reach the item_type branch.
##
## Adding a value here is safe: .tres files store the literal string, so existing
## resources are untouched.
@export_enum("equipable", "consumable", "material", "quest", "key", "misc") var item_type: String = "misc"
@export var is_stackable: bool = false
@export var max_stack: int = 99
@export var hidden_from_inventory: bool = false
@export var sell_price_ore: int = 0
@export var sell_price_crowns: int = 0
@export var sell_price_drots: int = 0

func is_sellable() -> bool:
	return sell_price_ore > 0 or sell_price_crowns > 0 or sell_price_drots > 0
