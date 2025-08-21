extends Skeleton3D
class_name ArticulatedPlayerMesh

# Creates a low-poly articulated humanoid using BoneAttachment3D nodes.
# The mesh stays under 500 triangles and the skeleton uses 13 bones.

const BONE_DATA := [
    {"name": "Hips", "parent": -1, "rest": Transform3D(Basis(), Vector3(0, 1.0, 0))},
    {"name": "Spine", "parent": 0, "rest": Transform3D(Basis(), Vector3(0, 0.3, 0))},
    {"name": "Chest", "parent": 1, "rest": Transform3D(Basis(), Vector3(0, 0.3, 0))},
    {"name": "Neck", "parent": 2, "rest": Transform3D(Basis(), Vector3(0, 0.25, 0))},
    {"name": "Head", "parent": 3, "rest": Transform3D(Basis(), Vector3(0, 0.25, 0))},
    {"name": "UpperArm.L", "parent": 2, "rest": Transform3D(Basis().rotated(Vector3(0,0,1), PI/2), Vector3(-0.35, 0.2, 0))},
    {"name": "LowerArm.L", "parent": 5, "rest": Transform3D(Basis().rotated(Vector3(0,0,1), PI/2), Vector3(-0.4, 0, 0))},
    {"name": "UpperArm.R", "parent": 2, "rest": Transform3D(Basis().rotated(Vector3(0,0,-1), PI/2), Vector3(0.35, 0.2, 0))},
    {"name": "LowerArm.R", "parent": 7, "rest": Transform3D(Basis().rotated(Vector3(0,0,-1), PI/2), Vector3(0.4, 0, 0))},
    {"name": "UpperLeg.L", "parent": 0, "rest": Transform3D(Basis(), Vector3(-0.15, -0.45, 0))},
    {"name": "LowerLeg.L", "parent": 9, "rest": Transform3D(Basis(), Vector3(0, -0.5, 0))},
    {"name": "UpperLeg.R", "parent": 0, "rest": Transform3D(Basis(), Vector3(0.15, -0.45, 0))},
    {"name": "LowerLeg.R", "parent": 11, "rest": Transform3D(Basis(), Vector3(0, -0.5, 0))},
]

func _ready() -> void:
    _create_skeleton()
    _create_meshes()

func _create_skeleton() -> void:
    clear_bones()
    for i in BONE_DATA.size():
        var b = BONE_DATA[i]
        add_bone(b.name)
        set_bone_parent(i, b.parent)
        set_bone_rest(i, b.rest)
        set_bone_pose(i, b.rest)

func _create_meshes() -> void:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.6, 0.4)
    mat.roughness = 0.7

    _attach_box("Hips", Vector3(0.4, 0.3, 0.2), Vector3(0, -0.15, 0), mat)
    _attach_box("Chest", Vector3(0.35, 0.4, 0.2), Vector3(0, 0.2, 0), mat)
    _attach_sphere("Head", 0.15, Vector3(0, 0.25, 0), mat)

    _attach_cylinder("UpperArm.L", 0.07, 0.4, Vector3(-0.2, 0, 0), PI/2, mat)
    _attach_cylinder("LowerArm.L", 0.06, 0.4, Vector3(-0.2, 0, 0), PI/2, mat)
    _attach_cylinder("UpperArm.R", 0.07, 0.4, Vector3(0.2, 0, 0), -PI/2, mat)
    _attach_cylinder("LowerArm.R", 0.06, 0.4, Vector3(0.2, 0, 0), -PI/2, mat)

    _attach_cylinder("UpperLeg.L", 0.09, 0.5, Vector3(0, -0.25, 0), 0.0, mat)
    _attach_cylinder("LowerLeg.L", 0.08, 0.5, Vector3(0, -0.25, 0), 0.0, mat)
    _attach_cylinder("UpperLeg.R", 0.09, 0.5, Vector3(0, -0.25, 0), 0.0, mat)
    _attach_cylinder("LowerLeg.R", 0.08, 0.5, Vector3(0, -0.25, 0), 0.0, mat)

    _attach_box("LowerLeg.L", Vector3(0.1, 0.05, 0.25), Vector3(0, -0.55, 0.1), mat)
    _attach_box("LowerLeg.R", Vector3(0.1, 0.05, 0.25), Vector3(0, -0.55, 0.1), mat)

func _attach_box(bone_name: String, size: Vector3, offset: Vector3, mat: Material) -> void:
    var box := BoxMesh.new()
    box.size = size
    box.material = mat
    _make_attachment(bone_name, box, offset, Basis())

func _attach_sphere(bone_name: String, radius: float, offset: Vector3, mat: Material) -> void:
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.radial_segments = 6
    sphere.rings = 4
    sphere.material = mat
    _make_attachment(bone_name, sphere, offset, Basis())

func _attach_cylinder(bone_name: String, radius: float, height: float, offset: Vector3, rot_z: float, mat: Material) -> void:
    var cylinder := CylinderMesh.new()
    cylinder.radius = radius
    cylinder.height = height
    cylinder.radial_segments = 6
    cylinder.rings = 1
    cylinder.material = mat
    var basis := Basis().rotated(Vector3(0, 0, 1), rot_z)
    _make_attachment(bone_name, cylinder, offset, basis)

func _make_attachment(bone_name: String, mesh: Mesh, offset: Vector3, basis: Basis) -> void:
    var attachment := BoneAttachment3D.new()
    attachment.bone_name = bone_name
    var mesh_instance := MeshInstance3D.new()
    mesh_instance.mesh = mesh
    mesh_instance.transform = Transform3D(basis, offset)
    attachment.add_child(mesh_instance)
    add_child(attachment)
