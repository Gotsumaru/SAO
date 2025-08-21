extends PlayerState
class_name IdleState

func enter() -> void:
	state_machine.animation_controller.play_idle()
	update_state_label("IDLE", Color.WHITE)
	
	# Apply friction to stop movement
	player.velocity.x = move_toward(player.velocity.x, 0, player.FRICTION * 0.1)
	player.velocity.z = move_toward(player.velocity.z, 0, player.FRICTION * 0.1)

func physics_update(delta: float) -> void:
	# Handle gravity
	if not player.is_on_floor():
		state_machine.change_state("airborne")
		return
	
	# Check for input
	var input_vector = get_input_vector()
	if input_vector.length() > 0.1:
		state_machine.change_state("locomotion")
		return
	
	# Apply friction
	player.velocity.x = move_toward(player.velocity.x, 0, player.FRICTION * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.FRICTION * delta)

func handle_input(event: InputEvent) -> void:
	# Jump
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY
		state_machine.change_state("airborne")
	
	# Attack
	if Input.is_action_just_pressed("attack"):
		state_machine.change_state("combat")

func can_transition_to(new_state: String) -> bool:
	# Idle can transition to any state
	return true