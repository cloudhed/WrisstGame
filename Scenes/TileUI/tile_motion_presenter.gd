class_name TileMotionPresenter
extends Node

const IDLE_SWAY_ROTATION := 0.045
const IDLE_SWAY_BOB := 3.0
const IDLE_SWAY_SPEED_MIN := 1.1
const IDLE_SWAY_SPEED_MAX := 1.8
const HOVER_PUSH_DISTANCE := 10.0
const HOVER_TILT_STRENGTH := 0.12
const MOTION_BLEND_SPEED := 8.0
const RETURN_BLEND_SPEED := 6.0

var tile_ui
var motion_base_position := Vector2.ZERO
var motion_last_applied_offset := Vector2.ZERO
var motion_hover_active := false
var motion_hover_mouse_global := Vector2.ZERO
var motion_suspended := false
var sway_phase := 0.0
var sway_speed := 1.35
var base_rotation_bias := 0.0


func setup(target_tile_ui) -> void:
	tile_ui = target_tile_ui
	motion_base_position = tile_ui.position
	_randomize_motion_profile()


func process_motion(delta: float) -> void:
	if tile_ui == null:
		return

	_update_motion_base_position()
	_apply_motion(delta)


func preserve_global_position_on_reparent(new_parent: Node) -> void:
	if tile_ui == null:
		return

	var previous_global_position: Vector2 = tile_ui.global_position
	tile_ui.reparent(new_parent)
	tile_ui.global_position = previous_global_position
	motion_base_position = tile_ui.position
	motion_last_applied_offset = Vector2.ZERO


func set_hover_motion(active: bool, mouse_global_pos := Vector2.ZERO) -> void:
	motion_hover_active = active
	if active:
		motion_hover_mouse_global = mouse_global_pos


func update_hover_motion_mouse(mouse_global_pos: Vector2) -> void:
	motion_hover_mouse_global = mouse_global_pos


func set_motion_suspended(active: bool) -> void:
	motion_suspended = active
	if active:
		motion_hover_active = false
		_apply_visual_offset(Vector2.ZERO)
		tile_ui.rotation = lerp_angle(tile_ui.rotation, 0.0, 0.85)
	else:
		motion_base_position = tile_ui.position
		motion_last_applied_offset = Vector2.ZERO


func is_hover_active() -> bool:
	return motion_hover_active


func _randomize_motion_profile() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(tile_ui.get_instance_id()))
	sway_phase = rng.randf_range(0.0, TAU)
	sway_speed = rng.randf_range(IDLE_SWAY_SPEED_MIN, IDLE_SWAY_SPEED_MAX)
	base_rotation_bias = rng.randf_range(-0.06, 0.06)


func _update_motion_base_position() -> void:
	var external_position: Vector2 = tile_ui.position - motion_last_applied_offset
	if external_position.distance_to(motion_base_position) > 0.01:
		motion_base_position = external_position


func _apply_motion(delta: float) -> void:
	if motion_suspended:
		motion_last_applied_offset = Vector2.ZERO
		return

	var time := Time.get_ticks_msec() * 0.001
	var idle_offset := Vector2(
		sin(time * sway_speed + sway_phase * 0.7) * 1.6,
		cos(time * (sway_speed * 1.15) + sway_phase) * IDLE_SWAY_BOB
	)
	var idle_rotation := base_rotation_bias + sin(time * sway_speed + sway_phase) * IDLE_SWAY_ROTATION

	var hover_offset := Vector2.ZERO
	var hover_rotation := 0.0
	if motion_hover_active:
		var push_direction: Vector2 = tile_ui.global_position + (tile_ui.size * 0.5) - motion_hover_mouse_global
		if push_direction.length_squared() > 0.0001:
			push_direction = push_direction.normalized()
			hover_offset = push_direction * HOVER_PUSH_DISTANCE
			hover_rotation = clamp(push_direction.x * HOVER_TILT_STRENGTH, -HOVER_TILT_STRENGTH, HOVER_TILT_STRENGTH)

	var blend_speed := MOTION_BLEND_SPEED if motion_hover_active else RETURN_BLEND_SPEED
	var target_offset := idle_offset + hover_offset
	var current_offset := motion_last_applied_offset.lerp(target_offset, clamp(delta * blend_speed, 0.0, 1.0))
	var target_rotation := idle_rotation + hover_rotation

	_apply_visual_offset(current_offset)
	tile_ui.rotation = lerp_angle(tile_ui.rotation, target_rotation, clamp(delta * blend_speed, 0.0, 1.0))


func _apply_visual_offset(new_offset: Vector2) -> void:
	tile_ui.position = motion_base_position + new_offset
	motion_last_applied_offset = new_offset