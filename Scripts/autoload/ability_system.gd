extends Node

const VALID_ABILITIES: Array[String] = ["body", "mind", "soul"]

## Numeric value for each tier. Change here to rebalance globally.
var tier_values: Dictionary = {
	"low":  -6,
	"mid":   0,
	"high":  7,
}

## Which tier each ability is currently assigned to.
var assignments: Dictionary = {
	"body": "low",
	"mind": "mid",
	"soul": "high",
}

## Full breakdown of the most recent check. Empty until the first roll.
var last_roll: Dictionary = {}

## Debug roll override: "rng" = normal, "nat1" = always 1, "nat20" = always 20.
var roll_override: String = "rng"


## Set one ability High, one Low; the third becomes Mid automatically.
func assign_abilities(high: String, low: String) -> void:
	if high not in VALID_ABILITIES or low not in VALID_ABILITIES:
		push_error("❌ AbilitySystem: Invalid ability name — high=%s low=%s" % [high, low])
		return
	if high == low:
		push_error("❌ AbilitySystem: High and Low cannot be the same ability.")
		return
	for a in VALID_ABILITIES:
		if a != high and a != low:
			assignments[a] = "mid"
	assignments[high] = "high"
	assignments[low]  = "low"


## Returns the numeric score for an ability based on its tier.
func get_score(ability_name: String) -> int:
	return tier_values.get(get_tier(ability_name), 0)


## Returns the tier string ("low", "mid", "high") for an ability.
func get_tier(ability_name: String) -> String:
	return assignments.get(ability_name.to_lower(), "mid")


## Resolves tier aliases ("high", "mid", "low") to the real ability name.
## "flat" and named abilities pass through unchanged.
func resolve_ability(ability_name: String) -> String:
	var lower := ability_name.to_lower()
	match lower:
		"high", "mid", "low":
			for ability in assignments.keys():
				if assignments[ability] == lower:
					return ability
			return VALID_ABILITIES[0]
		_:
			return lower


## Rolls 1d20 + ability score + bonus vs dc. Natural 20 always succeeds.
## Accepts real ability names, tier aliases ("high"/"mid"/"low"), or "flat" (no score added).
func perform_check(ability_name: String, dc: int, bonus: int = 0) -> Dictionary:
	var resolved: String = resolve_ability(ability_name)
	var roll: int
	match roll_override:
		"nat1":  roll = 1
		"nat20": roll = 20
		_:       roll = randi_range(1, 20)
	var score: int = 0 if resolved == "flat" else get_score(resolved)
	var total: int = roll + score + bonus
	var nat_20: bool = roll == 20
	return {
		"success": nat_20 or total >= dc,
		"nat_20":  nat_20,
		"roll":    roll,
		"total":   total,
		"dc":      dc,
	}


## True if the ability is assigned to the given tier.
func is_tier(ability_name: String, tier: String) -> bool:
	return get_tier(ability_name) == tier.to_lower()


func get_save_data() -> Dictionary:
	return {
		"tier_values": tier_values.duplicate(),
		"assignments": assignments.duplicate(),
	}


func load_save_data(data: Dictionary) -> void:
	if data.has("tier_values"):
		tier_values = data["tier_values"].duplicate()
	if data.has("assignments"):
		assignments = data["assignments"].duplicate()
