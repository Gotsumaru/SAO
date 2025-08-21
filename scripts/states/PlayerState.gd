extends RefCounted
class_name PlayerState

# Base class for all player states
var player: CharacterBody3D
var state_machine: PlayerStateMachine

func _init(player_ref: CharacterBody3D, sm: PlayerStateMachine):
	player = player_ref
	state_machine = sm

# Override these in child classes
func enter() -> void:
	pass

func exit() -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass

func can_transition_to(new_state: String) -> bool:
	return true

# Utility functions for common state logic
func get_input_vector() -> Vector2:
	return state_machine.input_handler.get_input_vector()

func get_movement_direction(input_vector: Vector2) -> Vector3:
	if input_vector.length() == 0:
		return Vector3.ZERO
	
	var direction = Vector3.ZERO
	if player.camera_pivot:
		direction = (player.camera_pivot.transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
	else:
		direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
	
	return direction

func rotate_player_to_direction(direction: Vector3, delta: float) -> void:
	if direction.length() > 0 and player.skeleton:
		var target_rotation = atan2(direction.x, direction.z)
		player.skeleton.rotation.y = lerp_angle(player.skeleton.rotation.y, target_rotation, 
												player.ROTATION_SPEED * delta)

func play_animation(anim_name: String) -> void:
	state_machine.animation_controller.play_simple_animation(anim_name)

func update_state_label(text: String, color: Color = Color.WHITE) -> void:
	if player.state_label:
		player.state_label.text = text
		player.state_label.modulate = color