extends Node
class_name InputHandler

# Input buffering - simplified with timers
var input_buffer: Array = []
var max_buffer_size: int = 10
var buffer_timeout: float = 0.2

# Coyote time
var coyote_time: float = 0.1
var coyote_timer: float = 0.0
var was_on_floor: bool = false

# Jump buffering
var jump_buffer_time: float = 0.1
var jump_buffer_timer: float = 0.0
var jump_requested: bool = false

var player: CharacterBody3D

signal action_buffered(action: String)
signal coyote_jump_available()
signal coyote_jump_expired()

func _init(player_ref: CharacterBody3D):
	player = player_ref

func _process(delta: float):
	_update_buffers(delta)
	_update_coyote_time(delta)

func _update_buffers(delta: float):
	# Update all input timers and remove expired inputs
	for i in range(input_buffer.size() - 1, -1, -1):
		var input_data = input_buffer[i]
		input_data.timer -= delta
		if input_data.timer <= 0:
			input_buffer.remove_at(i)
	
	# Update jump buffer
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta
		if jump_buffer_timer <= 0:
			jump_requested = false

func _update_coyote_time(delta: float):
	var is_on_floor = player.is_on_floor()
	
	# Start coyote time when leaving ground
	if was_on_floor and not is_on_floor:
		coyote_timer = coyote_time
		coyote_jump_available.emit()
	
	# Update coyote timer
	if coyote_timer > 0:
		coyote_timer -= delta
		if coyote_timer <= 0:
			coyote_jump_expired.emit()
	
	# Reset coyote time when landing
	if is_on_floor:
		coyote_timer = 0.0
	
	was_on_floor = is_on_floor

func buffer_input(action: String):
	var input_data = {
		"action": action,
		"timer": buffer_timeout  # Use timer instead of timestamp
	}
	
	input_buffer.append(input_data)
	action_buffered.emit(action)
	
	# Maintain buffer size
	while input_buffer.size() > max_buffer_size:
		input_buffer.pop_front()
	
	# Special handling for jump
	if action == "jump":
		jump_requested = true
		jump_buffer_timer = jump_buffer_time

func consume_buffered_input(action: String) -> bool:
	# Find and consume the most recent instance of this action
	for i in range(input_buffer.size() - 1, -1, -1):
		var input_data = input_buffer[i]
		if input_data.action == action:
			input_buffer.remove_at(i)
			return true
	return false

func has_buffered_input(action: String) -> bool:
	for input_data in input_buffer:
		if input_data.action == action:
			return true
	return false

func can_coyote_jump() -> bool:
	return coyote_timer > 0.0

func can_buffer_jump() -> bool:
	return jump_requested and jump_buffer_timer > 0.0

func consume_jump() -> bool:
	var can_jump = false
	
	# Check for regular ground jump
	if player.is_on_floor():
		can_jump = true
	
	# Check for coyote time jump
	elif can_coyote_jump():
		can_jump = true
		coyote_timer = 0.0  # Consume coyote time
	
	# Check for buffered jump
	elif can_buffer_jump():
		if player.is_on_floor() or can_coyote_jump():
			can_jump = true
			jump_requested = false
			jump_buffer_timer = 0.0
	
	return can_jump

func get_buffered_actions() -> Array:
	var actions = []
	for input_data in input_buffer:
		actions.append(input_data.action)
	return actions

func clear_buffer():
	input_buffer.clear()
	jump_requested = false
	jump_buffer_timer = 0.0

func get_input_vector() -> Vector2:
	var input = Vector2()
	
	# Check for buffered movement (less common but possible)
	if has_buffered_input("move_forward"):
		input.y -= 1
		consume_buffered_input("move_forward")
	elif Input.is_action_pressed("move_forward"):
		input.y -= 1
	
	if has_buffered_input("move_backward"):
		input.y += 1
		consume_buffered_input("move_backward")
	elif Input.is_action_pressed("move_backward"):
		input.y += 1
	
	if has_buffered_input("move_left"):
		input.x -= 1
		consume_buffered_input("move_left")
	elif Input.is_action_pressed("move_left"):
		input.x -= 1
	
	if has_buffered_input("move_right"):
		input.x += 1
		consume_buffered_input("move_right")
	elif Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Fallback to direct key input
	if input.length() == 0:
		if Input.is_key_pressed(KEY_Z) or Input.is_key_pressed(KEY_UP):
			input.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input.y += 1
		if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT):
			input.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input.x += 1
	
	return input.normalized()

# Debug information
func get_debug_info() -> Dictionary:
	return {
		"buffered_inputs": input_buffer.size(),
		"coyote_time_remaining": coyote_timer,
		"jump_buffer_active": jump_requested,
		"jump_buffer_remaining": jump_buffer_timer
	}
