extends Node
class_name MovementController

var player: CharacterBody3D
var terminal_velocity: float = -20.0

# Movement curves and modifiers
var surface_modifiers: Dictionary = {
	"default": {"friction": 1.0, "acceleration": 1.0},
	"ice": {"friction": 0.2, "acceleration": 0.5},
	"mud": {"friction": 2.0, "acceleration": 0.3},
	"grass": {"friction": 0.8, "acceleration": 1.2}
}

# Physics state
var momentum_preservation: float = 0.95
var air_control_factor: float = 0.3
var current_surface: String = "default"

signal surface_changed(new_surface: String)

func _init(player_ref: CharacterBody3D):
	player = player_ref

func get_acceleration_multiplier(speed_ratio: float) -> float:
	# Exponential acceleration curve (fast start, plateau) - implemented as function
	if speed_ratio < 0.5:
		return 2.0 - (speed_ratio * 0.8)  # 2.0 -> 1.6
	else:
		return 1.6 - ((speed_ratio - 0.5) * 1.6)  # 1.6 -> 0.8

func apply_movement(direction: Vector3, target_speed: float, delta: float, is_airborne: bool = false) -> void:
	if direction.length() == 0:
		_apply_friction(delta, is_airborne)
		return
	
	var surface_data = surface_modifiers.get(current_surface, surface_modifiers["default"])
	var effective_acceleration = player.ACCELERATION * surface_data.acceleration
	var effective_speed = target_speed
	
	if is_airborne:
		effective_acceleration *= air_control_factor
		effective_speed *= 0.7
	
	# Calculate acceleration based on current speed vs target
	var current_speed = Vector2(player.velocity.x, player.velocity.z).length()
	var speed_ratio = min(current_speed / effective_speed, 1.0)
	var curve_multiplier = get_acceleration_multiplier(speed_ratio)
	
	var final_acceleration = effective_acceleration * curve_multiplier
	var target_velocity = direction * effective_speed
	
	# Apply momentum preservation in turns
	if not is_airborne:
		var velocity_2d = Vector2(player.velocity.x, player.velocity.z)
		var target_2d = Vector2(target_velocity.x, target_velocity.z)
		var dot_product = velocity_2d.normalized().dot(target_2d.normalized())
		
		# If turning sharply, preserve some momentum
		if dot_product < 0.5 and velocity_2d.length() > 2.0:
			var preserved_velocity = velocity_2d * momentum_preservation * (1.0 - abs(dot_product))
			target_2d = target_2d.lerp(preserved_velocity, 0.3)
			target_velocity.x = target_2d.x
			target_velocity.z = target_2d.y
	
	# Apply movement
	player.velocity.x = move_toward(player.velocity.x, target_velocity.x, final_acceleration * delta)
	player.velocity.z = move_toward(player.velocity.z, target_velocity.z, final_acceleration * delta)

func _apply_friction(delta: float, is_airborne: bool = false) -> void:
	var surface_data = surface_modifiers.get(current_surface, surface_modifiers["default"])
	var friction = player.FRICTION * surface_data.friction
	
	if is_airborne:
		friction = player.AIR_FRICTION
	
	player.velocity.x = move_toward(player.velocity.x, 0, friction * delta)
	player.velocity.z = move_toward(player.velocity.z, 0, friction * delta)

func apply_gravity(delta: float) -> void:
	if player.velocity.y > terminal_velocity:
		player.velocity.y -= player.GRAVITY * delta
		player.velocity.y = max(player.velocity.y, terminal_velocity)

func apply_jump(jump_strength: float) -> void:
	player.velocity.y = jump_strength

func detect_surface() -> void:
	# Detect surface type based on what player is standing on
	if player.is_on_floor() and player.get_slide_collision_count() > 0:
		var collision = player.get_slide_collision(0)
		if collision:
			var surface_name = _get_surface_from_collision(collision)
			if surface_name != current_surface:
				current_surface = surface_name
				surface_changed.emit(current_surface)

func _get_surface_from_collision(collision) -> String:
	# Check collision material or metadata to determine surface type
	# For now, return default - could be extended to check material names
	if collision.get_collider().has_meta("surface_type"):
		return collision.get_collider().get_meta("surface_type")
	return "default"

func get_current_surface() -> String:
	return current_surface

func set_surface_modifier(surface: String, friction_mult: float, accel_mult: float) -> void:
	surface_modifiers[surface] = {
		"friction": friction_mult,
		"acceleration": accel_mult
	}

# Advanced movement features
func apply_lean_system(direction: Vector3, speed: float, delta: float) -> void:
	# Make player lean into turns for more realistic movement
	if not player.skeleton:
		return
	
	var velocity_2d = Vector2(player.velocity.x, player.velocity.z)
	var direction_2d = Vector2(direction.x, direction.z)
	
	if velocity_2d.length() > 1.0 and direction_2d.length() > 0:
		# Calculate turn angle
		var cross_product = velocity_2d.normalized().cross(direction_2d.normalized())
		var lean_angle = clamp(cross_product * speed * 0.1, -0.3, 0.3)
		
		# Apply lean to spine/torso
		var target_rotation = Vector3(0, 0, lean_angle)
		player.skeleton.rotation = player.skeleton.rotation.lerp(target_rotation, 5.0 * delta)
	else:
		# Return to upright position
		player.skeleton.rotation = player.skeleton.rotation.lerp(Vector3.ZERO, 3.0 * delta)

func get_movement_info() -> Dictionary:
	return {
		"speed": Vector2(player.velocity.x, player.velocity.z).length(),
		"direction": Vector2(player.velocity.x, player.velocity.z).normalized(),
		"surface": current_surface,
		"is_airborne": not player.is_on_floor(),
		"vertical_velocity": player.velocity.y
	}
