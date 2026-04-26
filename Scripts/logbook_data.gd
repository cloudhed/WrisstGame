class_name LogbookData
## Static lookup for all logbook entry definitions.
## Dialogue commands reference entries by ID; display text and hierarchy live here.
##
## To add a new entry: add a key to ENTRIES with "text" and optional "parent".
## Then use [@ADD_LOGBOOK my_entry_id] in dialogue to activate it.

const ENTRIES: Dictionary = {
	# ── Main Quest: Find a Way Home ──
	"find_way_home": {
		"text": "Find a way back home",
		"parent": "",
	},
	"search_answers_caarth": {
		"text": "Search for answers in Caarth",
		"parent": "find_way_home",
	},

	# ── Nautinto: Earn Access to the Hall ──
	"nautinto_hall_access": {
		"text": "Earn access to Nautinto's hall",
		"parent": "",
	},
	"nautinto_slime": {
		"text": "Collect teqqellon slime × 3",
		"parent": "nautinto_hall_access",
	},
	"nautinto_shenche": {
		"text": "Find a shenche loot",
		"parent": "nautinto_hall_access",
	},

	# ── Tavo-Pavo's Ledger of Favors (MQ-03) ──
	"tavo_favors": {
		"text": "Tavo-Pavo's tasks — the Ledger of Favors",
		"parent": "",
	},
	"investigate_mines": {
		"text": "Investigate the mines",
		"parent": "tavo_favors",
	},
	"find_noise_source": {
		"text": "Find the source of the noise",
		"parent": "investigate_mines",
	},
}


## Returns the entry dict for a given ID, or an empty dict if not found.
static func get_entry(id: String) -> Dictionary:
	return ENTRIES.get(id, {})


## Returns true if the entry exists in the database.
static func has_entry(id: String) -> bool:
	return ENTRIES.has(id)


## Returns an ordered array of entry IDs: top-level first, children after parent.
static func get_ordered_ids() -> Array[String]:
	var result: Array[String] = []

	# First pass: top-level entries (no parent)
	for id in ENTRIES:
		var parent: String = ENTRIES[id].get("parent", "")
		if parent.is_empty():
			result.append(id)
			# Second pass: immediate children of this entry
			for child_id in ENTRIES:
				if ENTRIES[child_id].get("parent", "") == id:
					result.append(child_id)
					# Third pass: grandchildren
					for grandchild_id in ENTRIES:
						if ENTRIES[grandchild_id].get("parent", "") == child_id:
							result.append(grandchild_id)

	return result
