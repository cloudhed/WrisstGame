extends Node

# Tile-related events
#Tile Drag
signal tile_drag_started(tile_ui: TileUI)
signal tile_drag_ended(tile_ui: TileUI)
#Tile Aim
signal tile_aim_started(tile_ui: TileUI)
signal tile_aim_ended(tile_ui: TileUI)
#Tile Played
signal tile_played(tile: Tile)

# Player-related events
signal player_ready(player: CombatPlayer)
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_hit
signal player_died

# Enemy-related events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_defeated

#Combat Text Log
signal combat_text_emitted(message: String)
# Floating Damage/Block/Heal Numbers
signal damage_popup_requested(world_position: Vector2, amount: int, effect_type: String)


#Tooltip
signal tile_tooltip_requested(icon: Texture, text: String, source: String, global_position: Vector2, tile_size: Vector2)
signal tooltip_hide_requested

#Combat-related events
signal leave_encounter_requested
signal change_scene_requested(scene: PackedScene)

	#Pre combat
	
	#Post combat
signal combat_over_screen_requested(text: String, type: String)

#Dialog Scene Changes
signal dialog_scene_change_requested(area_key: String)

# Overworld interaction prompts
signal overworld_interact_prompt_requested(text: String)
signal overworld_interact_prompt_hidden

# Barter/trading
signal barter_requested(shop: Resource)
signal barter_closed
