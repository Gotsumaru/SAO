extends PlayerState
class_name AirborneState

var is_jumping: bool = false

func enter() -> void:
	is_jumping = player.velocity.y > 0
	if is_jumping:
		state_machine.animation_controller.play_jump()
		update_state_label("JUMPING", Color.CYAN)
	else:
		state_machine.animation_controller.play_falling()
		update_state_label("FALLING", Color.ORANGE)

func physics_update(delta: float) -> void:
	# Apply gravity with enhanced physics
	state_machine.movement_controller.apply_gravity(delta)
	
	# Check if we've landed
	if player.is_on_floor():
		# Determine next state based on input
		var input_vector = get_input_vector()
		if input_vector.length() > 0.1:
			state_machine.change_state("locomotion")
		else:
			state_machine.change_state("idle")
		return
	
	# Limited air control using movement controller
	var input_vector = get_input_vector()
	if input_vector.length() > 0:
		var direction = get_movement_direction(input_vector)
		var target_speed = player.WALK_SPEED  # Movement controller handles air reduction
		state_machine.movement_controller.apply_movement(direction, target_speed, delta, true)
		
		# Rotate player (slower in air)
		rotate_player_to_direction(direction, delta * 0.5)
	
	# Update state based on vertical velocity
	if player.velocity.y <= 0 and is_jumping:
		is_jumping = false
		state_machine.animation_controller.play_falling()
		update_state_label("FALLING", Color.ORANGE)

func handle_input(event: InputEvent) -> void:
	# Coyote time jump implementation
	if Input.is_action_just_pressed("jump"):
		state_machine.input_handler.buffer_input("jump")
		if state_machine.input_handler.consume_jump():
			state_machine.movement_controller.apply_jump(player.JUMP_VELOCITY)
			is_jumping = true
			state_machine.animation_controller.play_jump()
			update_state_label("JUMPING", Color.CYAN)
	
	# Attack in air
	if Input.is_action_just_pressed("attack"):
		# Could implement air attacks later
		pass

func can_transition_to(new_state: String) -> bool:
	# Can only leave airborne state when on ground or forced
	return player.is_on_floor() or new_state == "special"