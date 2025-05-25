class_name DamagePopup
extends Control

@onready var label: Label = $DamageNumber


func setup(amount: int, color: Color) -> void:
	label.text = str(amount)
	label.modulate = color
	position.y -= 20  # offset up from target

	var tween := get_tree().create_tween()
	tween.tween_property(self, "position:y", position.y - 50, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.connect("finished", Callable(self, "_on_tween_finished"))

func _on_tween_finished() -> void:
	queue_free()
