extends CharacterBody3D
class_name PlayerOptimized

# Movement parameters
const WALK_SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 8.0
const ACCELERATION = 10.0
const FRICTION = 10.0
const AIR_FRICTION = 2.0
const GRAVITY = 20.0
const ROTATION_SPEED = 10.0

# Node references
var skeleton: Node3D
var camera_pivot: Node3D
var camera: Camera3D
var camera_arm: SpringArm3D
var state_label: Label3D
var animation_player: AnimationPlayer

# Camera variables
var camera_rotation_x: float = 0.0
var camera_rotation_y: float = 0.0
var mouse_sensitivity: float = 0.003

# Player stats
var max_health: int = 100
var current_health: int = 100
var stamina: float = 100.0
var max_stamina: float = 100.0

# State machine
var state_machine: PlayerStateMachine

func _ready():
	# Find node references
	skeleton = get_node_or_null("Skeleton")
	camera_pivot = get_node_or_null("CameraPivot")
	camera_arm = get_node_or_null("CameraPivot/CameraArm")
	camera = get_node_or_null("CameraPivot/CameraArm/Camera3D")
	state_label = get_node_or_null("StateLabel")
	animation_player = get_node_or_null("AnimationPlayer")
	
	# Configure mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Configure camera
	if camera_arm:
		camera_arm.add_excluded_object(self.get_rid())
	
	# Initialize state machine
	state_machine = PlayerStateMachine.new(self)
	add_child(state_machine)
	
	# Load animations
	if animation_player:
		load_animations()
	
	# Debug info
	print("🎮 Joueur optimisé initialisé")
	print("📍 Position initiale: ", global_position)
	
	# Verify nodes
	if not camera_pivot:
		print("⚠️ CameraPivot non trouvé!")
	if not skeleton:
		print("⚠️ Skeleton non trouvé!")
	if not animation_player:
		print("⚠️ AnimationPlayer non trouvé!")

func _input(event):
	# Camera mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		camera_rotation_y -= event.relative.x * mouse_sensitivity
		camera_rotation_x -= event.relative.y * mouse_sensitivity
		camera_rotation_x = clamp(camera_rotation_x, -1.4, 1.4)
	
	# Mouse capture toggle
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Update camera rotation
	if camera_pivot:
		camera_pivot.rotation.y = camera_rotation_y
		camera_pivot.rotation.x = camera_rotation_x
	
	# Apply movement
	move_and_slide()
	
	# Debug info (throttled)
	if Engine.get_process_frames() % 30 == 0:
		update_debug_info()

func update_debug_info():
	var current_room = get_current_room()
	if current_room:
		var state_name = state_machine.get_current_state_name() if state_machine else "none"
		print("🎮 Salle: ", current_room.name, " | État: ", state_name, 
			  " | Stamina: ", int(stamina), "%")

func get_current_room() -> Node3D:
	var level_builder = get_node_or_null("/root/Main")
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
	if state_machine:
		var special_state = state_machine.states.get("special") as SpecialState
		if special_state:
			special_state.start_death()
			state_machine.force_state("special")

func stun(duration: float = 1.0):
	if state_machine:
		var special_state = state_machine.states.get("special") as SpecialState
		if special_state:
			special_state.start_stun()
			state_machine.force_state("special")

func dodge():
	if state_machine:
		var special_state = state_machine.states.get("special") as SpecialState
		if special_state:
			special_state.start_dodge()
			state_machine.change_state("special")

func load_animations():
	if not animation_player:
		return
	
	var animation_library = preload("res://animations/player_animations.tres")
	if animation_library:
		animation_player.add_animation_library("", animation_library)
		print("✅ Animations chargées")
	else:
		print("⚠️ Impossible de charger les animations")

# Input handling is now done by states through the state machine
# Camera controls remain in main player for responsiveness