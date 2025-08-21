@tool
extends Resource
class_name HumanoidMesh

# Generates a simple low-poly humanoid mesh programmatically
static func create_humanoid_mesh() -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Create a simple humanoid shape with basic proportions
	# Head (sphere approximation with 8 faces)
	_add_sphere_section(vertices, normals, uvs, indices, Vector3(0, 1.6, 0), 0.15, 8, 6)
	
	# Torso (elongated box)
	_add_box_section(vertices, normals, uvs, indices, Vector3(0, 1.0, 0), Vector3(0.35, 0.5, 0.2))
	
	# Arms (cylinders)
	_add_cylinder_section(vertices, normals, uvs, indices, Vector3(-0.4, 1.15, 0), 0.08, 0.5, 6)
	_add_cylinder_section(vertices, normals, uvs, indices, Vector3(0.4, 1.15, 0), 0.08, 0.5, 6)
	
	# Legs (cylinders)
	_add_cylinder_section(vertices, normals, uvs, indices, Vector3(-0.15, 0.4, 0), 0.1, 0.8, 6)
	_add_cylinder_section(vertices, normals, uvs, indices, Vector3(0.15, 0.4, 0), 0.1, 0.8, 6)
	
	# Feet (small boxes)
	_add_box_section(vertices, normals, uvs, indices, Vector3(-0.15, 0.05, 0.1), Vector3(0.2, 0.1, 0.3))
	_add_box_section(vertices, normals, uvs, indices, Vector3(0.15, 0.05, 0.1), Vector3(0.2, 0.1, 0.3))
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

static func _add_sphere_section(vertices: PackedVector3Array, normals: PackedVector3Array, 
								uvs: PackedVector2Array, indices: PackedInt32Array,
								center: Vector3, radius: float, rings: int, segments: int):
	var start_vertex = vertices.size()
	
	for i in range(rings + 1):
		var v = float(i) / rings
		var phi = PI * v
		var y = cos(phi)
		var sin_phi = sin(phi)
		
		for j in range(segments + 1):
			var u = float(j) / segments
			var theta = 2.0 * PI * u
			var x = sin_phi * cos(theta)
			var z = sin_phi * sin(theta)
			
			var pos = center + Vector3(x, y, z) * radius
			var normal = Vector3(x, y, z).normalized()
			
			vertices.append(pos)
			normals.append(normal)
			uvs.append(Vector2(u, v))
	
	# Generate triangles
	for i in range(rings):
		for j in range(segments):
			var current = start_vertex + i * (segments + 1) + j
			var next = start_vertex + i * (segments + 1) + j + 1
			var below = start_vertex + (i + 1) * (segments + 1) + j
			var below_next = start_vertex + (i + 1) * (segments + 1) + j + 1
			
			indices.append(current)
			indices.append(below)
			indices.append(next)
			
			indices.append(next)
			indices.append(below)
			indices.append(below_next)

static func _add_box_section(vertices: PackedVector3Array, normals: PackedVector3Array,
							 uvs: PackedVector2Array, indices: PackedInt32Array,
							 center: Vector3, size: Vector3):
	var start_vertex = vertices.size()
	var half_size = size * 0.5
	
	# Box vertices (8 corners)
	var corners = [
		Vector3(-1, -1, -1), Vector3(1, -1, -1), Vector3(1, 1, -1), Vector3(-1, 1, -1),
		Vector3(-1, -1, 1), Vector3(1, -1, 1), Vector3(1, 1, 1), Vector3(-1, 1, 1)
	]
	
	# Face definitions (vertex indices and normals)
	var faces = [
		[0, 1, 2, 3, Vector3(0, 0, -1)], # Front
		[5, 4, 7, 6, Vector3(0, 0, 1)],  # Back
		[4, 0, 3, 7, Vector3(-1, 0, 0)], # Left
		[1, 5, 6, 2, Vector3(1, 0, 0)],  # Right
		[3, 2, 6, 7, Vector3(0, 1, 0)],  # Top
		[4, 5, 1, 0, Vector3(0, -1, 0)]  # Bottom
	]
	
	for face in faces:
		var face_normal = face[4]
		var face_verts = [face[0], face[1], face[2], face[3]]
		
		for i in range(4):
			var corner = corners[face_verts[i]]
			var pos = center + corner * half_size
			vertices.append(pos)
			normals.append(face_normal)
			uvs.append(Vector2(float(i % 2), float(i / 2)))
		
		var base_idx = start_vertex + vertices.size() - 4
		indices.append(base_idx)
		indices.append(base_idx + 1)
		indices.append(base_idx + 2)
		indices.append(base_idx)
		indices.append(base_idx + 2)
		indices.append(base_idx + 3)

static func _add_cylinder_section(vertices: PackedVector3Array, normals: PackedVector3Array,
								  uvs: PackedVector2Array, indices: PackedInt32Array,
								  center: Vector3, radius: float, height: float, segments: int):
	var start_vertex = vertices.size()
	var half_height = height * 0.5
	
	# Generate vertices for top and bottom circles
	for level in range(2):
		var y = half_height if level == 1 else -half_height
		for i in range(segments):
			var angle = 2.0 * PI * float(i) / segments
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			
			vertices.append(center + Vector3(x, y, 0))
			normals.append(Vector3(x, 0, z).normalized())
			uvs.append(Vector2(float(i) / segments, float(level)))
	
	# Side faces
	for i in range(segments):
		var next = (i + 1) % segments
		var bottom1 = start_vertex + i
		var bottom2 = start_vertex + next
		var top1 = start_vertex + segments + i
		var top2 = start_vertex + segments + next
		
		indices.append(bottom1)
		indices.append(top1)
		indices.append(bottom2)
		
		indices.append(bottom2)
		indices.append(top1)
		indices.append(top2)