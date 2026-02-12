extends Control

# --- CONFIGURATION ---
const SAVE_DIR = "res://Narrative/"

# Map your command logic here for auto-complete/UI generation
const COMMAND_TEMPLATES = {
	"Show Portrait": "@SHOW_PORTRAIT base",
	"Hide Portrait": "@HIDE_PORTRAIT",
	"Show Extra": "@SHOW_EXTRA base",
	"Hide Extra": "@HIDE_EXTRA",
	"Show Scene (Slide)": "@SHOW_SCENE debug_01",
	"Hide Scene": "@HIDE_SCENE",
	"Show Zone": "@SHOW_ZONE Klyftet/",
	"Play Music": "@PLAY_MUSIC res://Audio/Music/",
	"Stop Music": "@STOP_MUSIC",
	"Fade Music Out": "@FADE_MUSIC_OUT",
	"Play Ambience": "@PLAY_AMBIENCE wind res://Audio/Ambience/",
	"Stop Ambience": "@STOP_AMBIENCE wind",
	"Stop All Ambience": "@STOP_ALL_AMBIENCE",
	"Start Combat": "@START_COMBAT res://Scenes/Enemies/",
	"Leave Encounter": "@LEAVE_ENCOUNTER",
	"Add Ore": "@ADD_ORE 10",
	"Remove Ore": "@REMOVE_ORE 10",
	"Add Item": "@ADD_ITEM item_id",
	"Remove Item": "@REMOVE_ITEM item_id",
	"Add Reputation": "@ADD_REPUTATION minttärä 10",
	"Set Scene From": "@SET_SCENE_FROM"
}

@onready var graph_edit = $GraphEdit
@onready var file_dialog = $FileDialog

# Context menu vars
var context_menu: PopupMenu
var context_menu_position: Vector2 = Vector2.ZERO

func _ready():
	# UI Connections
	$SaveButton.pressed.connect(_on_save_pressed)
	$LoadButton.pressed.connect(_on_load_pressed)
	file_dialog.file_selected.connect(_on_file_selected)
	
	# Graph Logic
	graph_edit.popup_request.connect(_on_popup_request)
	graph_edit.connection_request.connect(_on_connection_request)
	graph_edit.disconnection_request.connect(_on_disconnection_request)
	
	# Create Right-Click Menu
	context_menu = PopupMenu.new()
	context_menu.name = "ContextMenu"
	context_menu.add_item("Narration / NPC Node", 0)
	context_menu.add_item("Choice Node", 1)
	context_menu.add_item("Command Node", 2)
	context_menu.add_separator()
	context_menu.add_item("Logic: Check Flag (Boolean)", 3)
	context_menu.add_item("Logic: Condition (Stat/Money)", 4)
	context_menu.add_item("Logic: Multi-Flag (Switch)", 5)
	
	context_menu.id_pressed.connect(_on_context_menu_item_selected)
	add_child(context_menu)

# --- CONTEXT MENU LOGIC ---

func _on_popup_request(at_position):
	context_menu_position = at_position
	context_menu.position = Vector2(get_viewport().get_mouse_position())
	context_menu.popup()

func _on_context_menu_item_selected(id):
	var spawn_pos = (context_menu_position + graph_edit.scroll_offset) / graph_edit.zoom
	create_node(id, spawn_pos)

# --- NODE CREATION FACTORY ---

func create_node(type_id: int, position_offset: Vector2, data: Dictionary = {}):
	var node = GraphNode.new()
	node.position_offset = position_offset
	node.resizable = true
	
	# Metadata to track what kind of JSON object this is
	node.set_meta("node_type", type_id) 

	# --- HEADER (ID + DELETE) ---
	# This creates a custom header because Godot 4 removed the built-in close button logic
	var id_box = HBoxContainer.new()
	
	var id_label = Label.new()
	id_label.text = "ID:"
	
	var id_edit = LineEdit.new()
	id_edit.name = "ID_Edit"
	id_edit.text = data.get("id", "node_" + str(randi() % 1000))
	id_edit.custom_minimum_size.x = 120
	id_edit.expand_to_text_length = true
	
	var del_btn = Button.new()
	del_btn.text = " X "
	del_btn.modulate = Color(1, 0.4, 0.4)
	del_btn.pressed.connect(func():
		# Safely remove connections before deleting node
		var node_name = node.name
		for conn in graph_edit.get_connection_list():
			if conn.from_node == node_name or conn.to_node == node_name:
				graph_edit.disconnect_node(conn.from_node, conn.from_port, conn.to_node, conn.to_port)
		node.queue_free()
	)
	
	id_box.add_child(id_label)
	id_box.add_child(id_edit)
	id_box.add_child(del_btn)
	
	node.add_child(id_box) # Child Index 0

	# --- NODE SPECIFIC CONTENT ---
	match type_id:
		0: # NARRATION
			node.title = "Narration / NPC"
			node.self_modulate = Color("e0cda6") # Beige
			
			# Input on Header (Slot 0)
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var name_edit = LineEdit.new() # Child 1
			name_edit.placeholder_text = "Speaker (Empty = Narrator)"
			name_edit.name = "Speaker_Edit"
			name_edit.text = data.get("name", "")
			node.add_child(name_edit)
			
			var text_edit = TextEdit.new() # Child 2
			text_edit.name = "Text_Edit"
			text_edit.text = data.get("text", "")
			text_edit.custom_minimum_size.y = 100
			text_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
			text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
			node.add_child(text_edit)
			
			# Flag Setting Container
			var flag_box = HBoxContainer.new() # Child 3
			var flag_edit = LineEdit.new()
			flag_edit.name = "SetFlag_Edit"
			flag_edit.placeholder_text = "Set Flag (e.g. met_mint)"
			flag_edit.text = data.get("set_flag", "")
			flag_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var flag_temp_chk = CheckBox.new()
			flag_temp_chk.name = "IsTemp_Chk"
			flag_temp_chk.text = "Temp?"
			flag_temp_chk.tooltip_text = "Is this a temporary session flag?"
			# Default to true if not specified, or load from data
			flag_temp_chk.button_pressed = true 
			if data.has("flag_type") and data["flag_type"] != "temp":
				flag_temp_chk.button_pressed = false
			
			flag_box.add_child(flag_edit)
			flag_box.add_child(flag_temp_chk)
			node.add_child(flag_box)
			
			# Output on Flag Box (Child 3)
			node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.WHITE)
			
		1: # CHOICE
			node.title = "Player Choice"
			node.self_modulate = Color("f2d65d") # Gold
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var add_btn = Button.new() # Child 1
			add_btn.text = "+ Add Option"
			add_btn.pressed.connect(func(): _add_dynamic_slot(node, "", true))
			node.add_child(add_btn)
			
			# Load Options (Children 2+)
			if data.has("options"):
				for opt in data.options:
					_add_dynamic_slot(node, opt.text, true)
			else:
				_add_dynamic_slot(node, "", true)
				
		2: # COMMAND
			node.title = "Command / Event"
			node.self_modulate = Color("a8b5b2") # Grey
			node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
			
			var cmd_list = OptionButton.new() # Child 1
			cmd_list.name = "Cmd_Selector"
			for key in COMMAND_TEMPLATES.keys():
				cmd_list.add_item(key)
			node.add_child(cmd_list)
			
			var cmd_edit = LineEdit.new() # Child 2
			cmd_edit.name = "Command_Edit"
			cmd_edit.custom_minimum_size.x = 250
			cmd_edit.text = data.get("command", "")
			node.add_child(cmd_edit)
			
			cmd_list.item_selected.connect(func(idx):
				var key = cmd_list.get_item_text(idx)
				cmd_edit.text = COMMAND_TEMPLATES[key]
			)
			
			# Clear Flags Logic
			var clear_edit = LineEdit.new() # Child 3
			clear_edit.name = "ClearFlag_Edit"
			clear_edit.placeholder_text = "Clear Flags (comma sep)"
			if data.has("clear_flag"):
				var c_arr = data.get("clear_flag", [])
				clear_edit.text = ", ".join(c_arr)
			node.add_child(clear_edit)
			
			# Output on ClearFlag (Child 3)
			node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.WHITE)
			
		3: # LOGIC (BOOLEAN)
			node.title = "Check Flag (Boolean)"
			node.self_modulate = Color("68aed4") # Blue
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var flag_edit = LineEdit.new() # Child 1
			flag_edit.name = "Flag_Edit"
			flag_edit.placeholder_text = "Flag Name"
			if data.has("check_flags"):
				var flags = data.check_flags.get("flags", [])
				if flags.size() > 0: flag_edit.text = flags[0]
			node.add_child(flag_edit)
			
			var l_pass = Label.new(); l_pass.text = "Success"; l_pass.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 2
			node.add_child(l_pass)
			node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.GREEN)
			
			var l_fail = Label.new(); l_fail.text = "Fail"; l_fail.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 3
			node.add_child(l_fail)
			node.set_slot(3, false, 0, Color.WHITE, true, 0, Color.RED)

		4: # LOGIC (CONDITION)
			node.title = "Check Stat/Money"
			node.self_modulate = Color("bda6e0") # Purple
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var type_opt = OptionButton.new() # Child 1
			type_opt.name = "CondType"
			type_opt.add_item("Currency (Ore)")
			type_opt.add_item("Stat")
			node.add_child(type_opt)
			
			var param1 = LineEdit.new() # Child 2
			param1.name = "Param1"
			param1.placeholder_text = "Name (e.g. ore)"
			node.add_child(param1)
			
			var param2 = LineEdit.new() # Child 3
			param2.name = "Param2"
			param2.placeholder_text = "Amount / Value"
			node.add_child(param2)
			
			var param3 = CheckBox.new() # Child 4
			param3.name = "Param3"
			param3.text = "Deduct?"
			node.add_child(param3)
			
			if data.has("condition"):
				if data.condition.has("currency"):
					type_opt.selected = 0
					param1.text = data.condition.currency
					param2.text = str(data.condition.amount)
					param3.button_pressed = data.condition.get("deduct", false)
				elif data.condition.has("stat"):
					type_opt.selected = 1
					param1.text = data.condition.stat
					param2.text = str(data.condition.is)
			
			var l1 = Label.new(); l1.text = "True"; l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 5
			node.add_child(l1)
			node.set_slot(5, false, 0, Color.WHITE, true, 0, Color.GREEN)
			
			var l2 = Label.new(); l2.text = "False"; l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT # Child 6
			node.add_child(l2)
			node.set_slot(6, false, 0, Color.WHITE, true, 0, Color.RED)
			
		5: # LOGIC (MULTI)
			node.title = "Check Multi-Flags"
			node.self_modulate = Color("68aed4") 
			node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
			
			var add_btn = Button.new() # Child 1
			add_btn.text = "+ Add Flag Check"
			add_btn.pressed.connect(func(): _add_dynamic_slot(node, "", true))
			node.add_child(add_btn)
			
			var def_label = Label.new() # Child 2
			def_label.text = "Default (Else)"
			def_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			node.add_child(def_label)
			node.set_slot(2, false, 0, Color.WHITE, true, 0, Color.RED)
			
			if data.has("check_temp_flags"):
				var flags = data.check_temp_flags
				for k in flags.keys():
					if k == "default": continue
					_add_dynamic_slot(node, k, true)

	graph_edit.add_child(node)
	return node

func _add_dynamic_slot(node: GraphNode, text: String, is_output: bool):
	var idx = node.get_child_count()
	var edit = LineEdit.new()
	edit.text = text
	edit.placeholder_text = "Value / Option Text..."
	edit.expand_to_text_length = true
	node.add_child(edit)
	node.set_slot(idx, false, 0, Color.WHITE, is_output, 0, Color.WHITE)

# --- CONNECTIONS ---
func _on_connection_request(from, from_slot, to, to_slot):
	graph_edit.connect_node(from, from_slot, to, to_slot)

func _on_disconnection_request(from, from_slot, to, to_slot):
	graph_edit.disconnect_node(from, from_slot, to, to_slot)

# --- EXPORT TO JSON ---
func _on_save_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.filters = ["*.json ; Wrisst Dialogue"]
	file_dialog.popup_centered()

func _on_load_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = ["*.json ; Wrisst Dialogue"]
	file_dialog.popup_centered()

func _on_file_selected(path):
	if file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		save_to_json(path)
	else:
		load_from_json(path)

func save_to_json(path):
	var export_array = []
	var nodes = graph_edit.get_children()
	var connections = graph_edit.get_connection_list()
	
	# Helper: Find node ID connected to a specific output port
	var get_target = func(node_name, port_idx):
		for conn in connections:
			if conn.from_node == node_name and conn.from_port == port_idx:
				var target_node = graph_edit.get_node(conn.to_node)
				return target_node.get_node("ID_Edit").text
		return ""

	for node in nodes:
		if not node is GraphNode: continue
		var type_id = node.get_meta("node_type")
		var node_id = node.get_node("ID_Edit").text
		var entry = {}
		entry["id"] = node_id
		
		match type_id:
			0: # Narration
				var spk = node.get_node("Speaker_Edit").text
				entry["type"] = "npc" if spk != "" else "narration"
				if spk != "": entry["name"] = spk
				entry["text"] = node.get_node("Text_Edit").text
				
				var flag_box = node.get_node("HBoxContainer") # SetFlag is in HBox
				var flag_edit = flag_box.get_child(0)
				var flag_chk = flag_box.get_child(1)
				
				if flag_edit.text != "":
					entry["set_flag"] = flag_edit.text
					entry["flag_type"] = "temp" if flag_chk.button_pressed else "perm"
				
				entry["next"] = get_target.call(node.name, 0) # Port 0 (Slot 3)
				
			1: # Choice
				entry["type"] = "choice"
				entry["options"] = []
				# Options start at Child 2.
				# Child 2 is Port 0. Child 3 is Port 1...
				var opt_start_child = 2
				for i in range(opt_start_child, node.get_child_count()):
					var child = node.get_child(i)
					if child is LineEdit:
						var port_idx = i - opt_start_child
						entry["options"].append({
							"text": child.text,
							"next": get_target.call(node.name, port_idx)
						})
						
			2: # Command
				entry["type"] = "command"
				entry["command"] = node.get_node("Command_Edit").text
				entry["clear"] = true
				
				var clear_txt = node.get_node("ClearFlag_Edit").text
				if clear_txt != "":
					var flags = clear_txt.split(",")
					entry["clear_flag"] = []
					for f in flags: entry["clear_flag"].append(f.strip_edges())
					
				entry["next"] = get_target.call(node.name, 0)
				
			3: # Logic Bool
				entry["type"] = "logic"
				entry["logic_type"] = "check_flags"
				entry["check_flags"] = {
					"flags": [node.get_node("Flag_Edit").text],
					"on_success": get_target.call(node.name, 0),
					"on_fail": get_target.call(node.name, 1)
				}
				
			4: # Logic Condition
				entry["type"] = "logic"
				entry["logic_type"] = "condition"
				var t = node.get_node("CondType").selected
				var p1 = node.get_node("Param1").text
				var p2 = node.get_node("Param2").text
				var p3 = node.get_node("Param3").button_pressed
				
				if t == 0: # Currency
					entry["condition"] = {
						"currency": p1, "amount": float(p2), "deduct": p3,
						"on_success": get_target.call(node.name, 0),
						"on_fail": get_target.call(node.name, 1)
					}
				else: # Stat
					entry["condition"] = {
						"stat": p1, "is": p2,
						"on_success": get_target.call(node.name, 0),
						"on_fail": get_target.call(node.name, 1)
					}
					
			5: # Logic Multi
				entry["type"] = "logic"
				entry["logic_type"] = "check_temp_flags_multi"
				entry["check_temp_flags"] = {}
				
				# Default is Child 2 -> Port 0
				entry["check_temp_flags"]["default"] = get_target.call(node.name, 0)
				
				# Dynamic starts Child 3 -> Port 1
				var dyn_start = 3
				for i in range(dyn_start, node.get_child_count()):
					var child = node.get_child(i)
					if child is LineEdit:
						var port = (i - dyn_start) + 1
						entry["check_temp_flags"][child.text] = get_target.call(node.name, port)

		export_array.append(entry)
		
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(export_array, "\t"))
		print("SUCCESS: Saved Wrisst JSON.")

# --- LOAD FROM JSON ---
func load_from_json(path):
	graph_edit.clear_connections()
	for c in graph_edit.get_children():
		if c is GraphNode: c.queue_free()
		
	var file = FileAccess.open(path, FileAccess.READ)
	if not file: return
	var data = JSON.parse_string(file.get_as_text())
	if not data is Array: return
		
	var nodes_by_id = {}
	var pos = Vector2(50, 50)
	
	# 1. Spawn Nodes
	for entry in data:
		var type = 0
		var t = entry.get("type", "narration")
		if t == "npc": type = 0
		elif t == "choice": type = 1
		elif t == "command": type = 2
		elif t == "logic":
			var lt = entry.get("logic_type", "")
			if lt == "condition": type = 4
			elif lt == "check_temp_flags_multi": type = 5
			else: type = 3
		
		var node = create_node(type, pos, entry)
		nodes_by_id[entry["id"]] = node
		pos.x += 420
		if pos.x > 2500: 
			pos.x = 50; pos.y += 350
			
	# 2. Connect
	await get_tree().process_frame
	
	for entry in data:
		var node = nodes_by_id.get(entry["id"])
		if not node: continue
		
		var connect_to = func(target_id, from_port):
			if target_id and nodes_by_id.has(target_id):
				graph_edit.connect_node(node.name, from_port, nodes_by_id[target_id].name, 0)
		
		if entry.has("next") and entry["next"] is String:
			connect_to.call(entry["next"], 0)
			
		if entry.get("type") == "choice":
			var opts = entry.get("options", [])
			for i in range(opts.size()):
				connect_to.call(opts[i]["next"], i)
				
		if entry.get("logic_type") == "check_flags":
			connect_to.call(entry.check_flags.get("on_success"), 0)
			connect_to.call(entry.check_flags.get("on_fail"), 1)

		if entry.get("logic_type") == "condition":
			connect_to.call(entry.condition.get("on_success"), 0)
			connect_to.call(entry.condition.get("on_fail"), 1)
			
		if entry.get("logic_type") == "check_temp_flags_multi":
			var flags = entry.get("check_temp_flags", {})
			connect_to.call(flags.get("default"), 0)
			var idx = 1
			# Assuming dynamic slots order matches key order (fragile but functional for restoration)
			for k in flags.keys():
				if k == "default": continue
				connect_to.call(flags[k], idx)
				idx += 1
