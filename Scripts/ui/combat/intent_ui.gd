class_name IntentUI
extends HBoxContainer

@onready var icon: TextureRect = $Icon
@onready var number: Label = $Number

func update_intent(intent: Intent) -> void:
	var combat = get_tree().get_current_scene() as Combat
	if combat and combat.combat_over:
		print("❌ Not updating intent — combat is over.")
		hide()
		return

	if not intent:
		hide()
		return

	icon.texture = intent.icon
	icon.visible = icon.texture != null
	number.text = str(intent.number)
	number.visible = intent.number.length() > 0
	show()
