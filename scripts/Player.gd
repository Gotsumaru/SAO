extends CharacterBody3D
class_name Player

# Paramètres de mouvement
const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 8.0
const ACCELERATION = 10.0
const FRICTION = 10.0
const AIR_FRICTION = 2.0
const GRAVITY = 20.0
const ROTATION_SPEED = 10.0

# États
enum State {
	IDLE,
	WALKING,
	RUNNING,
	JUMPING,
	FALLING,
	COMBAT
}

var current_state: State = State.IDLE
var current_speed: float = WALK_SPEED
var is_running: bool = false

# Références (on les cherche par nom si pas @onready)
var mesh_container: Node3D
var camera_pivot: Node3D
var camera: Camera3D
var camera_arm: SpringArm3D
var state_label: Label3D

# Variables pour la caméra
var camera_rotation_x: float = 0.0
var camera_rotation_y: float = 0.0
var mouse_sensitivity: float = 0.003

# Stats du joueur
var max_health: int = 100
var current_health: int = 100
var stamina: float = 100.0
var max_stamina: float = 100.0

func _ready():
	# Trouve les nodes par leur nom
	mesh_container = get_node_or_null("MeshContainer")
	camera_pivot = get_node_or_null("CameraPivot")
	camera_arm = get_node_or_null("CameraPivot/CameraArm")
	camera = get_node_or_null("CameraPivot/CameraArm/Camera3D")
	state_label = get_node_or_null("StateLabel")
	
	# Configure la souris
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Configure la caméra
	if camera_arm:
		camera_arm.add_excluded_object(self.get_rid())
	
	# Debug info
	print("🎮 Joueur initialisé")
	print("📍 Position initiale: ", global_position)
	
	# Vérifie que les nodes sont trouvés
	if not camera_pivot:
		print("⚠️ CameraPivot non trouvé!")
	if not mesh_container:
		print("⚠️ MeshContainer non trouvé!")

func _input(event):
	# Gestion de la caméra avec la souris
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation_y -= event.relative.x * mouse_sensitivity
		camera_rotation_x -= event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x, -1.4, 1.4)
	
	# Libération de la souris (ESC)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Sprint
	if Input.is_action_just_pressed("sprint"):
		is_running = true
	elif Input.is_action_just_released("sprint"):
		is_running = false
	
	# Saut
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		change_state(State.JUMPING)

func _physics_process(delta):
	# Gravité
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
		if velocity.y < 0 and current_state != State.FALLING:
			change_state(State.FALLING)
	elif current_state == State.FALLING or current_state == State.JUMPING:
		change_state(State.IDLE)
	
	# Input de mouvement
	var input_vector = get_input_vector()
	
	# Vitesse actuelle
	current_speed = RUN_SPEED if is_running and stamina > 0 else WALK_SPEED
	
	# Gestion stamina
	if is_running and input_vector.length() > 0:
		stamina = max(0, stamina - 30 * delta)
		if stamina <= 0:
			is_running = false
	else:
		stamina = min(max_stamina, stamina + 20 * delta)
	
	# Mouvement
	if input_vector.length() > 0:
		# Direction relative à la caméra
		var direction = Vector3.ZERO
		if camera_pivot:
			direction = (camera_pivot.transform.basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
		else:
			direction = Vector3(input_vector.x, 0, input_vector.y).normalized()
		
		# Accélération
		var target_velocity = direction * current_speed
		var accel = ACCELERATION if is_on_floor() else AIR_FRICTION
		
		velocity.x = move_toward(velocity.x, target_velocity.x, accel * delta)
		velocity.z = move_toward(velocity.z, target_velocity.z, accel * delta)
		
		# Rotation du mesh
		if direction.length() > 0 and mesh_container:
			var target_rotation = atan2(direction.x, direction.z)
			mesh_container.rotation.y = lerp_angle(mesh_container.rotation.y, target_rotation, ROTATION_SPEED * delta)
		
		# État
		if is_on_floor():
			if is_running and stamina > 0:
				change_state(State.RUNNING)
			else:
				change_state(State.WALKING)
	else:
		# Friction
		var friction = FRICTION if is_on_floor() else AIR_FRICTION
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
		
		if is_on_floor() and velocity.length() < 0.1:
			change_state(State.IDLE)
	
	# Rotation caméra
	if camera_pivot:
		camera_pivot.rotation.y = camera_rotation_y
		camera_pivot.rotation.x = camera_rotation_x
	
	# Applique le mouvement
	move_and_slide()
	
	# Debug
	update_debug_info()

func get_input_vector() -> Vector2:
	var input = Vector2()
	
	# Actions définies
	if Input.is_action_pressed("move_forward"):
		input.y -= 1
	if Input.is_action_pressed("move_backward"):
		input.y += 1
	if Input.is_action_pressed("move_left"):
		input.x -= 1
	if Input.is_action_pressed("move_right"):
		input.x += 1
	
	# Alternative avec les touches directes si les actions ne sont pas définies
	if not Input.get_action_strength("move_forward"):
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input.y -= 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input.y += 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			input.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			input.x += 1
	
	return input.normalized()

func change_state(new_state: State):
	if current_state == new_state:
		return
	
	current_state = new_state
	
	# Update le label si il existe
	if state_label:
		match new_state:
			State.IDLE:
				state_label.text = "IDLE"
				state_label.modulate = Color.WHITE
			State.WALKING:
				state_label.text = "WALKING"
				state_label.modulate = Color.GREEN
			State.RUNNING:
				state_label.text = "RUNNING"
				state_label.modulate = Color.YELLOW
			State.JUMPING:
				state_label.text = "JUMPING"
				state_label.modulate = Color.CYAN
			State.FALLING:
				state_label.text = "FALLING"
				state_label.modulate = Color.ORANGE
			State.COMBAT:
				state_label.text = "COMBAT"
				state_label.modulate = Color.RED

func update_debug_info():
	if Engine.get_process_frames() % 30 == 0:
		var current_room = get_current_room()
		if current_room:
			print("🎮 Salle: ", current_room.name, " | État: ", State.keys()[current_state], 
				  " | Stamina: ", int(stamina), "%")

func get_current_room() -> Node3D:
	var level_builder = get_node_or_null("/root/World")
	if level_builder and level_builder.has_method("get_room_at_position"):
		return level_builder.get_room_at_position(global_position)
	return null

func take_damage(amount: int):
	current_health = max(0, current_health - amount)
	print("💔 Dégâts: ", amount, " | Vie: ", current_health, "/", max_health)
	
	if current_health <= 0:
		die()

func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	print("💚 Soin: ", amount, " | Vie: ", current_health, "/", max_health)

func die():
	print("☠️ Game Over!")
	global_position = Vector3(0, 1, 0)
	current_health = max_health
	stamina = max_stamina
