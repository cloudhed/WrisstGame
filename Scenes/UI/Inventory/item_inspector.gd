class_name ItemInspector
extends VBoxContainer

## The middle column of the inventory screen: everything known about one item.
##
## Numbers are derived from the item's tile bundle by [ItemStatFormatter], so
## nothing here has to be authored per item and nothing drifts when a tile is
## retuned. The tile strip shows what the item actually puts into the pile.

signal equip_requested(item: EquipableItem)
signal unequip_requested(item: EquipableItem)

const TILE_GRID_CARD_SCENE_PATH := "res://Scenes/TileUI/tile_grid_card.tscn"

var item: InventoryItem = null

var _is_equipped: bool = false
var _tile_card_scene: PackedScene = null

@onready var empty_label: Label = %EmptyLabel
## Holds everything above the action button. The button sits outside it, so no
## amount of content can ever push the button out from under the cursor.
@onready var content_scroll: ScrollContainer = %ContentScroll
@onready var icon_rect: TextureRect = %IconRect
@onready var name_label: Label = %NameLabel
@onready var type_label: Label = %TypeLabel
@onready var top_divider: HSeparator = %TopDivider
@onready var stat_list: HBoxContainer = %StatList
@onready var stat_column: VBoxContainer = %StatColumn
@onready var stat_column_b: VBoxContainer = %StatColumnB
@onready var stat_row_template: HBoxContainer = %StatRowTemplate
@onready var tile_strip: ScrollContainer = %TileStrip
@onready var tile_row: HBoxContainer = %TileRow
@onready var mid_divider: HSeparator = %MidDivider
@onready var description_scroll: ScrollContainer = %DescriptionScroll
@onready var description_label: RichTextLabel = %DescriptionLabel
@onready var action_button: Button = %ActionButton


func _ready() -> void:
	action_button.pressed.connect(_on_action_pressed)
	clear()


func clear() -> void:
	item = null
	_is_equipped = false
	_clear_tile_strip()

	empty_label.visible = true
	content_scroll.visible = false
	action_button.visible = false


func show_item(p_item: InventoryItem, p_is_equipped: bool) -> void:
	if p_item == null:
		clear()
		return

	item = p_item
	_is_equipped = p_is_equipped

	empty_label.visible = false
	content_scroll.visible = true
	for node in [name_label, type_label, top_divider]:
		node.visible = true

	var category_id := ItemCategory.classify(item)

	# Most items have no icon yet, so the slot collapses rather than leaving a
	# 96px hole above the name.
	icon_rect.texture = item.icon
	icon_rect.visible = item.icon != null

	name_label.text = item.name
	name_label.add_theme_color_override("font_color", ItemCategory.color(category_id))
	type_label.text = _type_line(category_id)

	_rebuild_stats()
	_rebuild_tile_strip()

	description_label.text = item.description
	description_scroll.visible = not item.description.is_empty()

	_update_action_button()


## "Weapon, 2-handed" for gear, plain category name for everything else.
func _type_line(category_id: String) -> String:
	if item is EquipableItem:
		var equip := item as EquipableItem
		if equip.hand_slot == "none":
			return ItemCategory.singular_name(category_id)
		return "%s, %s" % [ItemCategory.singular_name(category_id), equip.hand_slot]
	return ItemCategory.singular_name(category_id)


## Fills the stat block, splitting the lines across two columns.
##
## Two columns rather than one because the panel is wider than a single
## label-and-value pair needs, and halving the row count halves how far the
## description below shifts between a one-line material and a nine-line weapon.
func _rebuild_stats() -> void:
	for column in [stat_column, stat_column_b]:
		for child in column.get_children():
			if child == stat_row_template:
				continue
			column.remove_child(child)
			child.queue_free()

	var lines := ItemStatFormatter.get_stat_lines(item)
	var first_column_count := int(ceil(lines.size() / 2.0))

	for i in lines.size():
		var line: Dictionary = lines[i]
		var row := stat_row_template.duplicate() as HBoxContainer
		# duplicate() copies the scene-unique-name flag, which would then clash
		# with the template's own name in the owner.
		row.unique_name_in_owner = false
		row.visible = true
		(row.get_child(0) as Label).text = line.label
		var value_label := row.get_child(1) as Label
		value_label.text = line.value
		value_label.add_theme_color_override("font_color", Color(line.color))

		if i < first_column_count:
			stat_column.add_child(row)
		else:
			stat_column_b.add_child(row)

	stat_list.visible = not lines.is_empty()
	mid_divider.visible = not lines.is_empty()


## Shows the tiles this item contributes, one card per distinct tile with a
## count beneath. Deduplicating keeps a twelve-tile bundle like the Long Stick
## to four cards instead of crowding out the description.
func _rebuild_tile_strip() -> void:
	_clear_tile_strip()

	if not item is EquipableItem:
		tile_strip.visible = false
		return

	var bundle: TileBundle = (item as EquipableItem).tile_bundle
	if bundle == null or bundle.tiles.is_empty():
		tile_strip.visible = false
		return

	var card_scene := _get_tile_card_scene()
	if card_scene == null:
		tile_strip.visible = false
		return

	# Preserves bundle order, which reads better than sorting.
	var distinct: Array[Tile] = []
	var counts: Dictionary = {}
	for tile in bundle.tiles:
		if tile == null:
			continue
		if counts.has(tile):
			counts[tile] += 1
		else:
			counts[tile] = 1
			distinct.append(tile)

	for tile in distinct:
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 2)

		var card = card_scene.instantiate()
		card.tile = tile
		column.add_child(card)

		var count_label := Label.new()
		count_label.text = "x%d" % counts[tile]
		count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		count_label.add_theme_font_size_override("font_size", 14)
		count_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.6))
		column.add_child(count_label)

		tile_row.add_child(column)

	tile_strip.visible = true


func _clear_tile_strip() -> void:
	for child in tile_row.get_children():
		tile_row.remove_child(child)
		child.queue_free()


func _get_tile_card_scene() -> PackedScene:
	if _tile_card_scene == null:
		_tile_card_scene = load(TILE_GRID_CARD_SCENE_PATH) as PackedScene
		if _tile_card_scene == null:
			push_error("❌ Failed to load tile grid card scene: " + TILE_GRID_CARD_SCENE_PATH)
	return _tile_card_scene


func _update_action_button() -> void:
	# Nothing in the codebase consumes an item yet, so only equipment gets a
	# button. Consumables and materials are inspect-only for now.
	if not item is EquipableItem:
		action_button.visible = false
		return

	action_button.visible = true
	action_button.text = "Unequip" if _is_equipped else "Equip"

	var blocked := _equip_blocked_reason()
	action_button.disabled = not _is_equipped and not blocked.is_empty()
	action_button.tooltip_text = blocked if action_button.disabled else ""


## Mirrors the silent rejection inside GameState.equip_offhand, so the button
## explains itself rather than appearing to do nothing.
func _equip_blocked_reason() -> String:
	var equip := item as EquipableItem
	if equip.equip_type == "offhand" \
			and GameState.equipped_weapon != null \
			and GameState.equipped_weapon.hand_slot == "2-handed":
		return "Your two-handed weapon needs both hands."
	return ""


func _on_action_pressed() -> void:
	if not item is EquipableItem:
		return
	if _is_equipped:
		unequip_requested.emit(item as EquipableItem)
	else:
		equip_requested.emit(item as EquipableItem)
