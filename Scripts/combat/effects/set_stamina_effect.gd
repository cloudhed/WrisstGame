class_name SetStaminaEffect
extends Effect

var amount := 0


func execute(targets: Array[Node]) -> void:
	var applied := false
	for target in targets:
		if not target or not ("stats" in target):
			continue

		var target_stats = target.stats
		if target_stats == null or not ("stamina" in target_stats):
			continue

		target_stats.stamina = amount
		applied = true

	if applied and sound:
		SFXPlayer.play(sound)