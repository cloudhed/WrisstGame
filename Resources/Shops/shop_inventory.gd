class_name ShopInventory
extends Resource

@export var shop_name: String = "Unnamed Shop"
## Markup applied to sell prices when auto-generating buy prices for sold-back items.
@export var markup_percent: float = 15.0
@export var shop_items: Array[ShopItemEntry] = []
