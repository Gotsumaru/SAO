extends PlayerState
class_name CombatState

var attack_timer: float = 0.0
var combo_count: int = 0
var max_combo: int = 3
var combo_window: float = 1.5

func enter() -> void:
	play_animation("attack_1")
	update_state_label("COMBAT", Color.RED)
	attack_timer = 0.6  # Attack duration
	combo_count = 1
	
	# Reduce movement speed during combat
	var input_vector = get_input_vector()
	if input_vector.length() > 0:
		var direction = get_movement_direction(input_vector)
		player.velocity.x = direction.x * player.WALK_SPEED * 0.3
		player.velocity.z = direction.z * player.WALK_SPEED * 0.3

func physics_update(delta: float) -> void:
	attack_timer -= delta
	
	# Handle gravity
	if not player.is_on_floor():
		player.velocity.y -= player.GRAVITY * delta
	
	# Apply friction during attack
	player.velocity.x = move_toward(player.velocity.x, 0, player.FRICTION * delta * 0.5)
	player.velocity.z = move_toward(player.velocity.z, 0, player.FRICTION * delta * 0.5)
	
	# Attack finished
	if attack_timer <= 0:
		# Check for input to determine next state
		var input_vector = get_input_vector()
		if input_vector.length() > 0.1 and player.is_on_floor():
			state_machine.change_state("locomotion")
		else:
			state_machine.change_state("idle")

func handle_input(event: InputEvent) -> void:
	# Combo attacks
	if Input.is_action_just_pressed("attack") and combo_count < max_combo and attack_timer > 0.2:
		combo_count += 1
		attack_timer = 0.6
		
		match combo_count:
			2:
				play_animation("attack_2")
			3:
				play_animation("attack_3")
			_:
				play_animation("attack_1")
	
	# Jump cancel (advanced technique)
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.JUMP_VELOCITY * 0.8  # Reduced jump
		state_machine.change_state("airborne")

func can_transition_to(new_state: String) -> bool:
	# Can interrupt combat with jump or special states
	return new_state in ["airborne", "special"] or attack_timer <= 0