extends Node
class_name PlayerStateMachine

var player: CharacterBody3D
var current_state: PlayerState
var states: Dictionary = {}
var state_history: Array[String] = []

# Controllers
var movement_controller: MovementController
var input_handler: InputHandler
var animation_controller: AnimationController

signal state_changed(from_state: String, to_state: String)

func _init(player_ref: CharacterBody3D):
	player = player_ref
	movement_controller = MovementController.new(player)
	input_handler = InputHandler.new(player)
	animation_controller = AnimationController.new(player)

func _ready():
	# Add controllers as children for proper processing
	add_child(movement_controller)
	add_child(input_handler)
	add_child(animation_controller)
	
	# Create all states
	states["idle"] = IdleState.new(player, self)
	states["locomotion"] = LocomotionState.new(player, self)
	states["airborne"] = AirborneState.new(player, self)
	states["combat"] = CombatState.new(player, self)
	states["special"] = SpecialState.new(player, self)
	
	# Connect input handler signals
	input_handler.action_buffered.connect(_on_action_buffered)
	
	# Start in idle state
	change_state("idle")

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func change_state(new_state_name: String) -> bool:
	if not states.has(new_state_name):
		print("⚠️ État inconnu: ", new_state_name)
		return false
	
	var old_state_name = current_state.get_script().get_path().get_file().get_basename() if current_state else "none"
	
	# Check if transition is allowed
	if current_state and not current_state.can_transition_to(new_state_name):
		return false
	
	# Exit current state
	if current_state:
		current_state.exit()
		state_history.append(old_state_name)
		
		# Keep only last 5 states in history
		if state_history.size() > 5:
			state_history.pop_front()
	
	# Enter new state
	current_state = states[new_state_name]
	current_state.enter()
	
	state_changed.emit(old_state_name, new_state_name)
	
	print("🔄 État: ", old_state_name, " -> ", new_state_name)
	return true

func get_current_state_name() -> String:
	if not current_state:
		return ""
	return current_state.get_script().get_path().get_file().get_basename()

func force_state(state_name: String) -> bool:
	# Force a state change without checking can_transition_to
	if not states.has(state_name):
		return false
	
	if current_state:
		current_state.exit()
	
	current_state = states[state_name]
	current_state.enter()
	return true

func get_previous_state() -> String:
	return state_history.back() if state_history.size() > 0 else ""

func _on_action_buffered(action: String):
	# Handle buffered input processing
	print("🎯 Action bufferisée: ", action)