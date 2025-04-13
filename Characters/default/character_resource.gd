class_name CharacterResource
extends Resource

@export var name: StringName = ""
@export var display_name: String = ""
@export var portrait: Texture2D
@export var voice_clip: AudioStream
@export var color: Color = Color.WHITE
@export var speech_bubble_color: Color = Color.WHITE
@export var speech_bubble_font: Font = null # Optional: fallback to default
@export var stats: Dictionary = {} # For combat or other systems (optional)
@export var default_flags: Dictionary
