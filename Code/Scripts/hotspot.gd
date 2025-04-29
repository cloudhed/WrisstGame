extends Area2D
class_name Hotspot

@export var unlocked_dialog_id: String = ""
@export var locked_dialog_id: String = ""
@export var required_flag: String = ""
@export var required_item: InventoryItem
@export var give_item: InventoryItem
@export var set_flag_on_click: String = ""
@export var disable_after_flag_set: bool = false
@export_enum("quest", "dialog", "event") var flag_type: String = "quest"
@export var always_give_item: bool = false

signal hotspot_triggered

func _ready() -> void:
	print("✅ Hotspot ready!")
	connect("input_event", Callable(self, "_on_input_event"))

func _on_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("🖱️ Hotspot clicked!")

		var flag_dict := get_flag_dict()

		var already_has_flag := false
		if required_flag != "":
			already_has_flag = GameState.has_flag(flag_dict, required_flag)

		var already_has_set_flag := false
		if set_flag_on_click != "":
			already_has_set_flag = GameState.has_flag(flag_dict, set_flag_on_click)

		var already_has_item := true
		if required_item != null:
			already_has_item = GameState.has_item(required_item)

		if already_has_flag or not already_has_item or already_has_set_flag:
			# Player already finished OR doesn't have required item -> lock behavior
			if locked_dialog_id != "":
				print("🔒 Hotspot locked after success or missing item - start dialog:", locked_dialog_id)
				hotspot_triggered.emit(locked_dialog_id)
			else:
				print("🚪 Nothing useful here anymore.")
			return

		# 🎯 Player does NOT have the flag yet → do normal hotspot behavior
		if give_item != null:
			GameState.add_item(give_item, 1)
			print("🎁 Given item:", give_item.name)

		if set_flag_on_click != "":
			GameState.set_flag(flag_dict, set_flag_on_click)
			print("🔖 Set", flag_type, "flag:", set_flag_on_click)

		if unlocked_dialog_id != "":
			print("🗝️ Unlocked - start dialog:", unlocked_dialog_id)
			hotspot_triggered.emit(unlocked_dialog_id)
		else:
			print("➡️ No dialog configured after unlocking.")

func get_flag_dict() -> Dictionary:
	match flag_type:
		"quest":
			return GameState.quest_flags
		"dialog":
			return GameState.dialog_flags
		"event":
			return GameState.event_flags
		_:
			return GameState.quest_flags
