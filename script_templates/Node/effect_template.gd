# meta-name: Effect
# meta-description: An effect which can be applied to a target.
class_name CombatEffect
extends Effect

var member_var := 0


func execute(targets: Array[Node]) -> void:
	print("Combat effect targets: %s" % targets)
	print("It does %s something" % member_var)
