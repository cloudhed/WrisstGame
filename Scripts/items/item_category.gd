class_name ItemCategory
extends RefCounted

## Buckets inventory items into the sections of the inventory list, and owns the
## colour each category paints its item names with.
##
## One section per equipment slot, so nothing is ambiguous: a pot lid is an
## Offhand, not a weapon that happens to be round. Sections with no items are
## hidden by the list, so an early-game player sees three or four headers rather
## than all seven.

const WEAPONS := "weapons"
const ARMOR := "armor"
const OFFHAND := "offhand"
const TRINKETS := "trinkets"
const CONSUMABLES := "consumables"
const MATERIALS := "materials"
const GENERAL := "general"

## Display order, top to bottom.
const ORDER: Array[String] = [
	WEAPONS, ARMOR, OFFHAND, TRINKETS, CONSUMABLES, MATERIALS, GENERAL,
]

const _DISPLAY_NAMES := {
	WEAPONS: "Weapons",
	ARMOR: "Armor",
	OFFHAND: "Offhand",
	TRINKETS: "Trinkets",
	CONSUMABLES: "Consumables",
	MATERIALS: "Materials",
	GENERAL: "General",
}

## Singular form, for the inspector's type line under an item's name.
const _SINGULAR_NAMES := {
	WEAPONS: "Weapon",
	ARMOR: "Armor",
	OFFHAND: "Offhand",
	TRINKETS: "Trinket",
	CONSUMABLES: "Consumable",
	MATERIALS: "Material",
	GENERAL: "Item",
}

## Hues chosen to sit inside the existing warm brown/green/gold palette rather
## than fight it: weapons run rust-orange, defensive gear runs cool, trinkets
## take the gold already used for the equipped accent.
const _COLORS := {
	WEAPONS: Color(0.86, 0.53, 0.33),
	ARMOR: Color(0.55, 0.72, 0.86),
	OFFHAND: Color(0.47, 0.66, 0.62),
	TRINKETS: Color(0.85, 0.72, 0.38),
	CONSUMABLES: Color(0.56, 0.80, 0.45),
	MATERIALS: Color(0.78, 0.70, 0.52),
	GENERAL: Color(0.86, 0.82, 0.72),
}


## Which section an item belongs in. Equipment is keyed off its slot, everything
## else off item_type.
static func classify(item: InventoryItem) -> String:
	if item == null:
		return GENERAL

	if item is EquipableItem:
		match (item as EquipableItem).equip_type:
			"weapon":
				return WEAPONS
			"armor":
				return ARMOR
			"offhand":
				return OFFHAND
			"trinket":
				return TRINKETS

	match item.item_type:
		"consumable":
			return CONSUMABLES
		"material":
			return MATERIALS
		_:
			# "misc", "quest", "key" and anything unrecognised land here, so a
			# newly authored item is always visible rather than silently dropped.
			return GENERAL


static func display_name(category_id: String) -> String:
	return _DISPLAY_NAMES.get(category_id, _DISPLAY_NAMES[GENERAL])


static func singular_name(category_id: String) -> String:
	return _SINGULAR_NAMES.get(category_id, _SINGULAR_NAMES[GENERAL])


static func color(category_id: String) -> Color:
	return _COLORS.get(category_id, _COLORS[GENERAL])
