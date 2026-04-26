extends CanvasLayer

@onready var debug_label = $DebugLabel
@onready var interact_prompt_label: Label = $InteractPromptLabel
@onready var health_label: Label = $HealthLabel


func _ready() -> void:
	if not Events.overworld_interact_prompt_requested.is_connected(_on_overworld_interact_prompt_requested):
		Events.overworld_interact_prompt_requested.connect(_on_overworld_interact_prompt_requested)
	if not Events.overworld_interact_prompt_hidden.is_connected(_on_overworld_interact_prompt_hidden):
		Events.overworld_interact_prompt_hidden.connect(_on_overworld_interact_prompt_hidden)

	GameState.health_changed.connect(_on_health_changed)
	_refresh_health_label()
	_on_overworld_interact_prompt_hidden()

func set_biome(biome_name: String) -> void:
	var text := biome_name
	if not is_inside_tree():
		return
	var combat := get_tree().get_current_scene() as Combat
	if combat and combat.player and combat.player.stats and combat.player.stats.has_method("get_debug_status_summary"):
		text += "\nCombat statuses: %s" % combat.player.stats.get_debug_status_summary()

	debug_label.text = text


func _on_overworld_interact_prompt_requested(text: String) -> void:
	interact_prompt_label.text = "[%s] %s" % ["Interact", text]
	interact_prompt_label.visible = true


func _on_overworld_interact_prompt_hidden() -> void:
	interact_prompt_label.visible = false


func _on_health_changed(_current: int, _maximum: int) -> void:
	_refresh_health_label()


func _refresh_health_label() -> void:
	if health_label == null or GameState.player_stats == null:
		return
	health_label.text = "HP: %d / %d" % [GameState.player_stats.health, GameState.player_stats.max_health]
	
#func _ready():
#	set_biome("Highest Biome: Shores\nAll Overlapping Biomes: (none)")

# Remove or comment out the _process function
# func _process(delta):
#     debug_label.text = "Biome: " + get_current_biome()
#     
# func get_current_biome() -> String:
#     return "Shores"
