extends MeshInstance3D

func _ready():
	# Generate an optimized low-poly humanoid mesh
	mesh = create_humanoid_mesh()

func create_humanoid_mesh() -> ArrayMesh:
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Simple humanoid made from optimized geometry (under 400 triangles total)
	
	# Torso (box)
	add_box(vertices, normals, uvs, indices, Vector3(0, 1.0, 0), Vector3(0.35, 0.5, 0.2))
	
	# Head (sphere-like with fewer faces)
	add_sphere(vertices, normals, uvs, indices, Vector3(0, 1.6, 0), 0.15, 6, 4)
	
	# Arms (simple cylinders)
	add_cylinder(vertices, normals, uvs, indices, Vector3(-0.4, 1.15, 0), 0.08, 0.5, 6)
	add_cylinder(vertices, normals, uvs, indices, Vector3(0.4, 1.15, 0), 0.08, 0.5, 6)
	
	# Legs (simple cylinders)
	add_cylinder(vertices, normals, uvs, indices, Vector3(-0.15, 0.4, 0), 0.1, 0.8, 6)
	add_cylinder(vertices, normals, uvs, indices, Vector3(0.15, 0.4, 0), 0.1, 0.8, 6)
	
	# Feet (small boxes)
	add_box(vertices, normals, uvs, indices, Vector3(-0.15, 0.05, 0.1), Vector3(0.2, 0.1, 0.3))
	add_box(vertices, normals, uvs, indices, Vector3(0.15, 0.05, 0.1), Vector3(0.2, 0.1, 0.3))
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func add_box(vertices: PackedVector3Array, normals: PackedVector3Array, 
			uvs: PackedVector2Array, indices: PackedInt32Array,
			center: Vector3, size: Vector3):
	var start_idx = vertices.size()
	var hs = size * 0.5
	
	# 8 vertices for a box
	var box_verts = [
		center + Vector3(-hs.x, -hs.y, -hs.z), # 0
		center + Vector3(hs.x, -hs.y, -hs.z),  # 1
		center + Vector3(hs.x, hs.y, -hs.z),   # 2
		center + Vector3(-hs.x, hs.y, -hs.z),  # 3
		center + Vector3(-hs.x, -hs.y, hs.z),  # 4
		center + Vector3(hs.x, -hs.y, hs.z),   # 5
		center + Vector3(hs.x, hs.y, hs.z),    # 6
		center + Vector3(-hs.x, hs.y, hs.z)    # 7
	]
	
	# Add vertices
	for v in box_verts:
		vertices.append(v)
	
	# Add normals (simple outward facing)
	for i in range(8):
		normals.append((box_verts[i] - center).normalized())
	
	# Add UVs (simple mapping)
	for i in range(8):
		uvs.append(Vector2(float(i % 2), float(i / 4)))
	
	# 12 triangles (2 per face, 6 faces)
	var box_indices = [
		# Front face
		start_idx + 0, start_idx + 1, start_idx + 2,
		start_idx + 0, start_idx + 2, start_idx + 3,
		# Back face
		start_idx + 5, start_idx + 4, start_idx + 7,
		start_idx + 5, start_idx + 7, start_idx + 6,
		# Left face
		start_idx + 4, start_idx + 0, start_idx + 3,
		start_idx + 4, start_idx + 3, start_idx + 7,
		# Right face
		start_idx + 1, start_idx + 5, start_idx + 6,
		start_idx + 1, start_idx + 6, start_idx + 2,
		# Top face
		start_idx + 3, start_idx + 2, start_idx + 6,
		start_idx + 3, start_idx + 6, start_idx + 7,
		# Bottom face
		start_idx + 4, start_idx + 5, start_idx + 1,
		start_idx + 4, start_idx + 1, start_idx + 0
	]
	
	for idx in box_indices:
		indices.append(idx)

func add_cylinder(vertices: PackedVector3Array, normals: PackedVector3Array,
				  uvs: PackedVector2Array, indices: PackedInt32Array,
				  center: Vector3, radius: float, height: float, segments: int):
	var start_idx = vertices.size()
	var half_height = height * 0.5
	
	# Add vertices for top and bottom rings
	for level in range(2):
		var y = half_height if level == 1 else -half_height
		for i in range(segments):
			var angle = 2.0 * PI * float(i) / segments
			var x = cos(angle) * radius
			var z = sin(angle) * radius
			
			vertices.append(center + Vector3(x, y, z))
			normals.append(Vector3(x, 0, z).normalized())
			uvs.append(Vector2(float(i) / segments, float(level)))
	
	# Create side faces
	for i in range(segments):
		var next_i = (i + 1) % segments
		var bottom = start_idx + i
		var bottom_next = start_idx + next_i
		var top = start_idx + segments + i
		var top_next = start_idx + segments + next_i
		
		# Two triangles per side face
		indices.append(bottom)
		indices.append(top)
		indices.append(bottom_next)
		
		indices.append(bottom_next)
		indices.append(top)
		indices.append(top_next)

func add_sphere(vertices: PackedVector3Array, normals: PackedVector3Array,
				uvs: PackedVector2Array, indices: PackedInt32Array,
				center: Vector3, radius: float, rings: int, segments: int):
	var start_idx = vertices.size()
	
	# Generate sphere vertices
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
			var current = start_idx + i * (segments + 1) + j
			var next = start_idx + i * (segments + 1) + j + 1
			var below = start_idx + (i + 1) * (segments + 1) + j
			var below_next = start_idx + (i + 1) * (segments + 1) + j + 1
			
			indices.append(current)
			indices.append(below)
			indices.append(next)
			
			indices.append(next)
			indices.append(below)
			indices.append(below_next)
