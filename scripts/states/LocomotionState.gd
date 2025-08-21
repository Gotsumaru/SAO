extends PlayerState
class_name LocomotionState

var is_running: bool = false

func enter() -> void:
	is_running = Input.is_action_pressed("sprint")

func physics_update(delta: float) -> void:
	# Handle gravity
	if not player.is_on_floor():
		state_machine.change_state("airborne")
		return
	
	# Get input
	var input_vector = get_input_vector()
	
	# No input = go to idle
	if input_vector.length() < 0.1:
		state_machine.change_state("idle")
		return
	
	# Update running state
	is_running = Input.is_action_pressed("sprint") and player.stamina > 0
	
	# Determine speed
	var target_speed = player.RUN_SPEED if is_running else player.WALK_SPEED
	
	# Stamina management
	if is_running:
		player.stamina = max(0, player.stamina - 30 * delta)
		if player.stamina <= 0:
			is_running = false
	else:
		player.stamina = min(player.max_stamina, player.stamina + 20 * delta)
	
	# Movement using enhanced movement controller
	var direction = get_movement_direction(input_vector)
	state_machine.movement_controller.apply_movement(direction, target_speed, delta, false)
	state_machine.movement_controller.detect_surface()
	state_machine.movement_controller.apply_lean_system(direction, target_speed, delta)
	
	# Rotate player to movement direction
	rotate_player_to_direction(direction, delta)
	
	# Animation and state display using AnimationController
	state_machine.animation_controller.play_locomotion()
	if is_running:
		update_state_label("RUNNING", Color.YELLOW)
	else:
		update_state_label("WALKING", Color.GREEN)

func handle_input(event: InputEvent) -> void:
	# Buffer inputs for better responsiveness
	if Input.is_action_just_pressed("jump"):
		state_machine.input_handler.buffer_input("jump")
		if state_machine.input_handler.consume_jump():
			state_machine.movement_controller.apply_jump(player.JUMP_VELOCITY)
			state_machine.change_state("airborne")
	
	# Attack
	if Input.is_action_just_pressed("attack"):
		state_machine.input_handler.buffer_input("attack")
		state_machine.change_state("combat")
	
	# Sprint toggle
	if Input.is_action_just_pressed("sprint"):
		is_running = true
	elif Input.is_action_just_released("sprint"):
		is_running = false

func can_transition_to(new_state: String) -> bool:
	# Can transition to any state
	return true