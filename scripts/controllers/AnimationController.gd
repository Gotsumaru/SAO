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

# Skeleton and procedural animation data
var skeleton: Skeleton3D
var bones := {}
var bone_rest := {}
var walk_time: float = 0.0

signal animation_started(animation_name: String)
signal animation_finished(animation_name: String)

func _init(player_ref: CharacterBody3D):
    player = player_ref

func _ready():
    animation_player = player.get_node_or_null("AnimationPlayer")
    animation_tree = player.get_node_or_null("AnimationTree")
    skeleton = player.get_node_or_null("Skeleton") as Skeleton3D

    if skeleton:
        _cache_bones()

    if animation_tree:
        animation_tree.active = true
        state_machine_playback = animation_tree.get("parameters/playback") as AnimationNodeStateMachinePlayback
        if animation_player:
            animation_player.animation_finished.connect(_on_animation_finished)
        print("✅ AnimationController initialisé")
    else:
        print("⚠️ AnimationTree non trouvé - utilisation d'animations procédurales")

func _process(delta: float):
    update_animation_parameters()
    if not animation_tree:
        update_procedural_animation(delta)

func _cache_bones():
    var names = [
        "UpperArm.L", "LowerArm.L", "UpperArm.R", "LowerArm.R",
        "UpperLeg.L", "LowerLeg.L", "UpperLeg.R", "LowerLeg.R",
        "Spine", "Chest", "Neck", "Head"
    ]
    for n in names:
        var idx = skeleton.find_bone(n)
        if idx != -1:
            bones[n] = idx
            bone_rest[n] = skeleton.get_bone_rest(idx)

func update_animation_parameters():
    if not player:
        return

    var velocity_2d = Vector2(player.velocity.x, player.velocity.z)
    movement_speed = velocity_2d.length()
    is_moving = movement_speed > 0.1
    is_airborne = not player.is_on_floor()

    var max_speed = player.RUN_SPEED if player.stamina > 0 else player.WALK_SPEED
    if is_moving and max_speed != 0:
        var normalized_speed = min(movement_speed / max_speed, 1.0)
        var movement_direction = velocity_2d.normalized()
        blend_position = movement_direction * normalized_speed
    else:
        blend_position = Vector2.ZERO

    if animation_tree:
        animation_tree.set("parameters/locomotion/blend_position", blend_position)
        animation_tree.set("parameters/is_moving/current", 1 if is_moving else 0)
        animation_tree.set("parameters/is_airborne/current", 1 if is_airborne else 0)
        animation_tree.set("parameters/movement_speed", movement_speed)

func update_procedural_animation(delta: float) -> void:
    if not skeleton:
        return
    walk_time += delta * movement_speed * 4.0
    if is_moving and player.is_on_floor():
        var swing := sin(walk_time)
        _set_bone_rotation("UpperArm.L", Vector3(deg2rad(20) * swing, 0, 0))
        _set_bone_rotation("LowerArm.L", Vector3(deg2rad(10) * swing, 0, 0))
        _set_bone_rotation("UpperArm.R", Vector3(deg2rad(-20) * swing, 0, 0))
        _set_bone_rotation("LowerArm.R", Vector3(deg2rad(-10) * swing, 0, 0))
        _set_bone_rotation("UpperLeg.L", Vector3(deg2rad(-30) * swing, 0, 0))
        _set_bone_rotation("LowerLeg.L", Vector3(deg2rad(20) * swing, 0, 0))
        _set_bone_rotation("UpperLeg.R", Vector3(deg2rad(30) * swing, 0, 0))
        _set_bone_rotation("LowerLeg.R", Vector3(deg2rad(-20) * swing, 0, 0))
    else:
        for n in bone_rest.keys():
            skeleton.set_bone_pose(bones[n], bone_rest[n])
    apply_basic_foot_ik()

func _set_bone_rotation(name: String, euler: Vector3):
    if not bones.has(name):
        return
    var idx = bones[name]
    var rest: Transform3D = bone_rest[name]
    var basis := rest.basis
    basis = basis.rotated(Vector3(1, 0, 0), euler.x)
    basis = basis.rotated(Vector3(0, 1, 0), euler.y)
    basis = basis.rotated(Vector3(0, 0, 1), euler.z)
    skeleton.set_bone_pose(idx, Transform3D(basis, rest.origin))

func apply_basic_foot_ik():
    _update_foot("LowerLeg.L")
    _update_foot("LowerLeg.R")

func _update_foot(name: String):
    if not bones.has(name):
        return
    var idx = bones[name]
    var global_pose: Transform3D = skeleton.get_bone_global_pose(idx)
    var from: Vector3 = global_pose.origin + Vector3(0, 0.2, 0)
    var to: Vector3 = global_pose.origin + Vector3(0, -0.8, 0)
    var space := skeleton.get_world_3d().direct_space_state
    var result := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, [player.get_rid()]))
    if result:
        global_pose.origin.y = result.position.y
        skeleton.set_bone_global_pose_override(idx, global_pose, 1.0, true)

func play_state(state_name: String) -> bool:
    if not state_machine_playback:
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
