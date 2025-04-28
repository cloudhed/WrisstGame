class_name DialogSceneResource
extends Resource

@export var background_texture: Texture2D #good fallback
@export var zone_scene: PackedScene

@export var music: AudioStream
@export var ambience: AudioStream
@export var sfx_library: Dictionary = {}

@export_file("*.json") var dialogue_path: String

@export var characters: Array[CharacterEntry] = []
@export var slide_deck: SlideDeck

@export var flags_required: Array[String] = []
@export var flags_set_on_start: Dictionary = {}
