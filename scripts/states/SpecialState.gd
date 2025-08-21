extends PlayerState
class_name SpecialState

enum SpecialType {
	DODGE,
	STUN,
	DEATH
}

var special_type: SpecialType = SpecialType.DODGE
var special_timer: float = 0.0

func enter() -> void:
	match special_type:
		SpecialType.DODGE:
			_enter_dodge()
		SpecialType.STUN:
			_enter_stun()
		SpecialType.DEATH:
			_enter_death()

func physics_update(delta: float) -> void:
	special_timer -= delta
	
	match special_type:
		SpecialType.DODGE:
			_physics_dodge(delta)
		SpecialType.STUN:
			_physics_stun(delta)
		SpecialType.DEATH:
			_physics_death(delta)

func _enter_dodge() -> void:
	play_animation("dodge")
	update_state_label("DODGE", Color.CYAN)
	special_timer = 0.4
	
	# Dodge in current facing direction or input direction
	var dodge_direction = Vector3.ZERO
	var input_vector = get_input_vector()
	
	if input_vector.length() > 0:
		dodge_direction = get_movement_direction(input_vector)
	else:
		# Dodge backwards if no input
		if player.skeleton:
			dodge_direction = -player.skeleton.transform.basis.z
	
	# Apply dodge impulse
	var dodge_force = 8.0
	player.velocity.x = dodge_direction.x * dodge_force
	player.velocity.z = dodge_direction.z * dodge_force

func _enter_stun() -> void:
	play_animation("stun")
	update_state_label("STUNNED", Color.PURPLE)
	special_timer = 1.0  # Stun duration
	
	# Stop movement
	player.velocity.x = 0
	player.velocity.z = 0

func _enter_death() -> void:
	play_animation("death")
	update_state_label("DEAD", Color.BLACK)
	special_timer = 2.0  # Death animation duration
	
	# Stop all movement
	player.velocity = Vector3.ZERO

func _physics_dodge(delta: float) -> void:
	# Apply friction during dodge
	player.velocity.x = move_toward(player.velocity.x, 0, player.FRICTION * delta * 2.0)
	player.velocity.z = move_toward(player.velocity.z, 0, player.FRICTION * delta * 2.0)
	
	# Handle gravity
	if not player.is_on_floor():
		player.velocity.y -= player.GRAVITY * delta
	
	# End dodge
	if special_timer <= 0:
		var input_vector = get_input_vector()
		if input_vector.length() > 0.1:
			state_machine.change_state("locomotion")
		else:
			state_machine.change_state("idle")

func _physics_stun(delta: float) -> void:
	# Handle gravity
	if not player.is_on_floor():
		player.velocity.y -= player.GRAVITY * delta
	
	# Apply friction
	player.velocity.x = move_toward(player.velocity.x, 0, player.FRICTION * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, player.FRICTION * delta)
	
	# End stun
	if special_timer <= 0:
		state_machine.change_state("idle")

func _physics_death(delta: float) -> void:
	# Handle gravity
	if not player.is_on_floor():
		player.velocity.y -= player.GRAVITY * delta
	
	# Apply friction
	player.velocity.x = move_toward(player.velocity.x, 0, player.FRICTION * delta * 5.0)
	player.velocity.z = move_toward(player.velocity.z, 0, player.FRICTION * delta * 5.0)
	
	# Respawn after death animation
	if special_timer <= 0:
		player.global_position = Vector3(0, 1, 0)
		player.current_health = player.max_health
		player.stamina = player.max_stamina
		state_machine.change_state("idle")

func handle_input(event: InputEvent) -> void:
	match special_type:
		SpecialType.DODGE:
			# Can't interrupt dodge
			pass
		SpecialType.STUN:
			# Can't act while stunned
			pass
		SpecialType.DEATH:
			# Can't act while dead
			pass

func start_dodge() -> void:
	special_type = SpecialType.DODGE

func start_stun() -> void:
	special_type = SpecialType.STUN

func start_death() -> void:
	special_type = SpecialType.DEATH

func can_transition_to(new_state: String) -> bool:
	# Special states can only be interrupted in specific cases
	match special_type:
		SpecialType.DODGE:
			return special_timer <= 0  # Must finish dodge
		SpecialType.STUN:
			return special_timer <= 0  # Must finish stun
		SpecialType.DEATH:
			return special_timer <= 0  # Must finish death
	return false