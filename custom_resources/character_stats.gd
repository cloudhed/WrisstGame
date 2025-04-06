class_name CharacterStats
extends Stats

@export var starting_deck: TilePile
@export var tiles_per_turn: int
@export var max_stamina: int

var stamina: int : set = set_stamina
var deck: TilePile
var discard: TilePile
var draw_pile: TilePile


func set_stamina(value: int) -> void:
	stamina = value
	stats_changed.emit()


func reset_stamina() -> void:
	self.stamina = max_stamina


func take_damage(damage: int) -> void:
	var initial_health := health
	super.take_damage(damage)
	if initial_health > health:
		Events.player_hit.emit()


func can_play_tile(tile: Tile) -> bool:
	return stamina >= tile.cost


func create_instance() -> Resource:
	var instance: CharacterStats = self.duplicate()
	instance.playername = playername
	instance.health = max_health
	instance.block = 0
	instance.reset_stamina()
	instance.deck = instance.starting_deck.duplicate()
	instance.draw_pile = TilePile.new()
	instance.discard = TilePile.new()
	return instance
