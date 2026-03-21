class_name ShopItemEntry
extends Resource

@export var item: InventoryItem
@export var stock: int = -1              ## -1 = unlimited
@export var buy_price_ore: int = 0
@export var buy_price_crowns: int = 0
@export var buy_price_drots: int = 0
@export var is_unique: bool = false      ## Disappears after purchase
