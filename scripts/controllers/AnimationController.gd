extends Node
class_name AnimationController

var player: CharacterBody3D
var animation_tree: AnimationTree
var animation_player: AnimationPlayer
var state_machine_playback: AnimationNodeStateMachinePlayback

# Animation parameters
var blend_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var movement_speed: float = 0.0
var is_airborne: bool = false
var is_attacking: bool = false

signal animation_started(animation_name: String)
signal animation_finished(animation_name: String)

func _init(player_ref: CharacterBody3D):
	player = player_ref

func _ready():
	animation_player = player.get_node_or_null("AnimationPlayer")
	animation_tree = player.get_node_or_null("AnimationTree")
	
	if animation_tree:
		animation_tree.active = true
		state_machine_playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
		
		# Connect animation finished signal
		if animation_player:
			animation_player.animation_finished.connect(_on_animation_finished)
		
		print("✅ AnimationController initialisé")
	else:
		print("⚠️ AnimationTree non trouvé - utilisation d'AnimationPlayer simple")

func _process(delta: float):
	if animation_tree:
		update_animation_parameters()

func update_animation_parameters():
	if not animation_tree:
		return
	
	# Update movement parameters
	var velocity_2d = Vector2(player.velocity.x, player.velocity.z)
	movement_speed = velocity_2d.length()
	is_moving = movement_speed > 0.1
	is_airborne = not player.is_on_floor()
	
	# Set blend position for locomotion blend space
	if is_moving:
		# Normalize velocity for blend space (-1 to 1 range)
		var max_speed = player.RUN_SPEED if player.stamina > 0 else player.WALK_SPEED
		var normalized_speed = min(movement_speed / max_speed, 1.0)
		
		# Set blend position (X: strafe, Y: forward/back)
		var movement_direction = velocity_2d.normalized()
		blend_position = movement_direction * normalized_speed
	else:
		blend_position = Vector2.ZERO
	
	# Update animation tree parameters
	animation_tree.set("parameters/locomotion/blend_position", blend_position)
	animation_tree.set("parameters/is_moving/current", 1 if is_moving else 0)
	animation_tree.set("parameters/is_airborne/current", 1 if is_airborne else 0)
	animation_tree.set("parameters/movement_speed", movement_speed)

func play_state(state_name: String) -> bool:
	if not state_machine_playback:
		# Fallback to simple animation player
		return play_simple_animation(state_name)
	
	if state_machine_playback.can_travel_to(state_name):
		state_machine_playback.travel(state_name)
		animation_started.emit(state_name)
		return true
	else:
		print("⚠️ Impossible de voyager vers l'état: ", state_name)
		return false

func play_simple_animation(anim_name: String) -> bool:
	if not animation_player:
		return false
	
	if animation_player.has_animation(anim_name):
		if animation_player.current_animation != anim_name:
			animation_player.play(anim_name)
			animation_started.emit(anim_name)
		return true
	else:
		print("⚠️ Animation non trouvée: ", anim_name)
		return false

# High-level animation functions for states
func play_idle():
	play_state("idle")

func play_locomotion():
	play_state("locomotion")

func play_jump():
	play_state("jump")

func play_falling():
	play_state("falling")

func play_attack(combo_index: int = 1):
	var attack_name = "attack_" + str(combo_index)
	play_state(attack_name)

func play_dodge():
	play_state("dodge")

func play_stun():
	play_state("stun")

func play_death():
	play_state("death")

# Animation blending control
func set_walk_run_blend(walk_weight: float):
	if animation_tree:
		animation_tree.set("parameters/locomotion_speed/blend_amount", walk_weight)

func set_turn_blend(turn_amount: float):
	if animation_tree:
		animation_tree.set("parameters/turn_blend", turn_amount)

# Advanced animation features
func trigger_one_shot(animation_name: String):
	if animation_tree:
		animation_tree.set("parameters/" + animation_name + "/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func is_one_shot_active(animation_name: String) -> bool:
	if not animation_tree:
		return false
	return animation_tree.get("parameters/" + animation_name + "/active")

func get_current_state() -> String:
	if state_machine_playback:
		return state_machine_playback.get_current_node()
	elif animation_player:
		return animation_player.current_animation
	return ""

func is_state_active(state_name: String) -> bool:
	return get_current_state() == state_name

# Root motion support (for future implementation)
func get_root_motion_transform() -> Transform3D:
	if animation_tree:
		return animation_tree.get_root_motion_transform()
	return Transform3D.IDENTITY

func apply_root_motion():
	if animation_tree and animation_tree.root_motion_track != NodePath():
		var root_motion = get_root_motion_transform()
		# Apply root motion to player movement
		# This would require integration with movement controller
		pass

# Debug information
func get_debug_info() -> Dictionary:
	return {
		"current_state": get_current_state(),
		"blend_position": blend_position,
		"movement_speed": movement_speed,
		"is_moving": is_moving,
		"is_airborne": is_airborne,
		"has_animation_tree": animation_tree != null
	}

func _on_animation_finished(animation_name: StringName):
	animation_finished.emit(animation_name)