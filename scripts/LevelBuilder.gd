extends Node3D
class_name LevelBuilder

# Configuration
const ROOM_SIZE = 10.0
const WALL_HEIGHT = 3.0
const WALL_THICKNESS = 0.2
const DOOR_WIDTH = 2.0
const DOOR_HEIGHT = 2.5

# Références
var rooms_container: Node3D
var connections_map: Dictionary = {}  # Stocke les connexions pour chaque salle
var rooms_nodes: Dictionary = {}      # Référence rapide aux nodes de salles

func _ready():
	rooms_container = Node3D.new()
	rooms_container.name = "Rooms"
	add_child(rooms_container)
	
	# Charge le niveau de test
	load_level("res://data/levels/test_level.json")

func load_level(json_path: String):
	if not FileAccess.file_exists(json_path):
		print("❌ Erreur : Fichier non trouvé - ", json_path)
		create_default_room()
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("❌ Erreur parsing JSON : ", json.get_error_message())
		return
	
	var level_data = json.data
	print("📋 Chargement niveau: ", level_data.get("name", "Sans nom"))
	generate_level(level_data)

func generate_level(data: Dictionary):
	# Nettoie les salles existantes
	for child in rooms_container.get_children():
		child.queue_free()
	
	connections_map.clear()
	rooms_nodes.clear()
	
	# Parse les connexions d'abord
	if data.has("connections"):
		parse_connections(data["connections"])
	
	# Génère les salles
	if data.has("rooms"):
		for room_data in data["rooms"]:
			create_room(room_data)
	
	print("✅ Niveau généré : ", data["rooms"].size(), " salles")
	print("🔗 Connexions : ", connections_map)

func parse_connections(connections: Array):
	"""Parse les connexions et crée une map bidirectionnelle"""
	for conn in connections:
		var from_id = conn["from"]
		var to_id = conn["to"]
		var direction = conn["direction"]
		
		# Ajoute la connexion dans le sens direct
		if not connections_map.has(from_id):
			connections_map[from_id] = {}
		connections_map[from_id][direction] = to_id
		
		# Ajoute la connexion inverse
		var inverse_direction = get_inverse_direction(direction)
		if not connections_map.has(to_id):
			connections_map[to_id] = {}
		connections_map[to_id][inverse_direction] = from_id

func get_inverse_direction(direction: String) -> String:
	match direction:
		"north": return "south"
		"south": return "north"
		"east": return "west"
		"west": return "east"
		_: return ""

func create_room(room_data: Dictionary):
	var room_id = room_data.get("id", -1)
	var x = room_data.get("x", 0) * ROOM_SIZE
	var z = room_data.get("y", 0) * ROOM_SIZE  # Y dans JSON = Z dans Godot 3D
	var room_type = room_data.get("type", "empty")
	
	# Crée le conteneur de la salle
	var room = Node3D.new()
	room.position = Vector3(x, 0, z)
	room.name = "Room_" + str(room_id)
	room.set_meta("room_id", room_id)
	room.set_meta("room_type", room_type)
	room.set_meta("room_data", room_data)
	
	# Sol de la salle
	create_floor(room, room_type)
	
	# Récupère les connexions pour cette salle
	var room_connections = connections_map.get(room_id, {})
	
	# Murs avec portes
	create_walls_with_doors(room, room_connections)
	
	# Ajoute les ennemis si définis
	if room_data.has("enemies"):
		for enemy_data in room_data["enemies"]:
			create_enemy_placeholder(room, enemy_data)
	
	# Ajoute un marker visuel pour le type de salle
	add_room_type_indicator(room, room_type)
	
	rooms_container.add_child(room)
	rooms_nodes[room_id] = room

func create_floor(room: Node3D, room_type: String):
	var floor = CSGBox3D.new()
	floor.size = Vector3(ROOM_SIZE - 0.5, 0.2, ROOM_SIZE - 0.5)
	floor.position.y = -0.1
	floor.use_collision = true
	floor.name = "Floor"
	
	# Matériau selon le type
	var material = StandardMaterial3D.new()
	match room_type:
		"combat":
			material.albedo_color = Color(0.5, 0.2, 0.2)  # Rouge sombre
		"treasure":
			material.albedo_color = Color(0.5, 0.4, 0.1)  # Or sombre
		"boss":
			material.albedo_color = Color(0.3, 0.1, 0.1)  # Rouge très sombre
		_:
			material.albedo_color = Color(0.3, 0.3, 0.3)  # Gris
	
	floor.material = material
	room.add_child(floor)

func create_walls_with_doors(room: Node3D, connections: Dictionary):
	"""Crée les murs avec des ouvertures pour les portes"""
	
	# Mur Nord
	if connections.has("north"):
		create_wall_with_door(room, "north")
	else:
		create_solid_wall(room, "north")
	
	# Mur Sud
	if connections.has("south"):
		create_wall_with_door(room, "south")
	else:
		create_solid_wall(room, "south")
	
	# Mur Est
	if connections.has("east"):
		create_wall_with_door(room, "east")
	else:
		create_solid_wall(room, "east")
	
	# Mur Ouest
	if connections.has("west"):
		create_wall_with_door(room, "west")
	else:
		create_solid_wall(room, "west")

func create_solid_wall(room: Node3D, direction: String):
	"""Crée un mur plein sans ouverture"""
	var wall = CSGBox3D.new()
	wall.use_collision = true
	wall.name = "Wall_" + direction
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.25, 0.25)
	wall.material = mat
	
	match direction:
		"north":
			wall.size = Vector3(ROOM_SIZE, WALL_HEIGHT, WALL_THICKNESS)
			wall.position = Vector3(0, WALL_HEIGHT/2, -ROOM_SIZE/2)
		"south":
			wall.size = Vector3(ROOM_SIZE, WALL_HEIGHT, WALL_THICKNESS)
			wall.position = Vector3(0, WALL_HEIGHT/2, ROOM_SIZE/2)
		"east":
			wall.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, ROOM_SIZE)
			wall.position = Vector3(ROOM_SIZE/2, WALL_HEIGHT/2, 0)
		"west":
			wall.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, ROOM_SIZE)
			wall.position = Vector3(-ROOM_SIZE/2, WALL_HEIGHT/2, 0)
	
	room.add_child(wall)

func create_wall_with_door(room: Node3D, direction: String):
	"""Crée un mur avec une ouverture pour la porte"""
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.25, 0.25)
	
	match direction:
		"north":
			# Mur gauche
			var wall_left = CSGBox3D.new()
			wall_left.size = Vector3((ROOM_SIZE - DOOR_WIDTH)/2, WALL_HEIGHT, WALL_THICKNESS)
			wall_left.position = Vector3(-(ROOM_SIZE/2 - wall_left.size.x/2), WALL_HEIGHT/2, -ROOM_SIZE/2)
			wall_left.use_collision = true
			wall_left.material = mat
			room.add_child(wall_left)
			
			# Mur droit
			var wall_right = CSGBox3D.new()
			wall_right.size = Vector3((ROOM_SIZE - DOOR_WIDTH)/2, WALL_HEIGHT, WALL_THICKNESS)
			wall_right.position = Vector3(ROOM_SIZE/2 - wall_right.size.x/2, WALL_HEIGHT/2, -ROOM_SIZE/2)
			wall_right.use_collision = true
			wall_right.material = mat
			room.add_child(wall_right)
			
			# Linteau au-dessus de la porte
			var lintel = CSGBox3D.new()
			lintel.size = Vector3(DOOR_WIDTH, WALL_HEIGHT - DOOR_HEIGHT, WALL_THICKNESS)
			lintel.position = Vector3(0, DOOR_HEIGHT + lintel.size.y/2, -ROOM_SIZE/2)
			lintel.use_collision = true
			lintel.material = mat
			room.add_child(lintel)
			
		"south":
			# Mur gauche
			var wall_left = CSGBox3D.new()
			wall_left.size = Vector3((ROOM_SIZE - DOOR_WIDTH)/2, WALL_HEIGHT, WALL_THICKNESS)
			wall_left.position = Vector3(-(ROOM_SIZE/2 - wall_left.size.x/2), WALL_HEIGHT/2, ROOM_SIZE/2)
			wall_left.use_collision = true
			wall_left.material = mat
			room.add_child(wall_left)
			
			# Mur droit
			var wall_right = CSGBox3D.new()
			wall_right.size = Vector3((ROOM_SIZE - DOOR_WIDTH)/2, WALL_HEIGHT, WALL_THICKNESS)
			wall_right.position = Vector3(ROOM_SIZE/2 - wall_right.size.x/2, WALL_HEIGHT/2, ROOM_SIZE/2)
			wall_right.use_collision = true
			wall_right.material = mat
			room.add_child(wall_right)
			
			# Linteau
			var lintel = CSGBox3D.new()
			lintel.size = Vector3(DOOR_WIDTH, WALL_HEIGHT - DOOR_HEIGHT, WALL_THICKNESS)
			lintel.position = Vector3(0, DOOR_HEIGHT + lintel.size.y/2, ROOM_SIZE/2)
			lintel.use_collision = true
			lintel.material = mat
			room.add_child(lintel)
			
		"east":
			# Mur avant
			var wall_front = CSGBox3D.new()
			wall_front.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, (ROOM_SIZE - DOOR_WIDTH)/2)
			wall_front.position = Vector3(ROOM_SIZE/2, WALL_HEIGHT/2, -(ROOM_SIZE/2 - wall_front.size.z/2))
			wall_front.use_collision = true
			wall_front.material = mat
			room.add_child(wall_front)
			
			# Mur arrière
			var wall_back = CSGBox3D.new()
			wall_back.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, (ROOM_SIZE - DOOR_WIDTH)/2)
			wall_back.position = Vector3(ROOM_SIZE/2, WALL_HEIGHT/2, ROOM_SIZE/2 - wall_back.size.z/2)
			wall_back.use_collision = true
			wall_back.material = mat
			room.add_child(wall_back)
			
			# Linteau
			var lintel = CSGBox3D.new()
			lintel.size = Vector3(WALL_THICKNESS, WALL_HEIGHT - DOOR_HEIGHT, DOOR_WIDTH)
			lintel.position = Vector3(ROOM_SIZE/2, DOOR_HEIGHT + lintel.size.y/2, 0)
			lintel.use_collision = true
			lintel.material = mat
			room.add_child(lintel)
			
		"west":
			# Mur avant
			var wall_front = CSGBox3D.new()
			wall_front.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, (ROOM_SIZE - DOOR_WIDTH)/2)
			wall_front.position = Vector3(-ROOM_SIZE/2, WALL_HEIGHT/2, -(ROOM_SIZE/2 - wall_front.size.z/2))
			wall_front.use_collision = true
			wall_front.material = mat
			room.add_child(wall_front)
			
			# Mur arrière
			var wall_back = CSGBox3D.new()
			wall_back.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, (ROOM_SIZE - DOOR_WIDTH)/2)
			wall_back.position = Vector3(-ROOM_SIZE/2, WALL_HEIGHT/2, ROOM_SIZE/2 - wall_back.size.z/2)
			wall_back.use_collision = true
			wall_back.material = mat
			room.add_child(wall_back)
			
			# Linteau
			var lintel = CSGBox3D.new()
			lintel.size = Vector3(WALL_THICKNESS, WALL_HEIGHT - DOOR_HEIGHT, DOOR_WIDTH)
			lintel.position = Vector3(-ROOM_SIZE/2, DOOR_HEIGHT + lintel.size.y/2, 0)
			lintel.use_collision = true
			lintel.material = mat
			room.add_child(lintel)
	
	# Ajoute un indicateur visuel de porte (frame lumineux)
	add_door_frame(room, direction)

func add_door_frame(room: Node3D, direction: String):
	"""Ajoute un cadre lumineux autour de la porte pour la rendre plus visible"""
	var frame = CSGBox3D.new()
	frame.name = "DoorFrame_" + direction
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.8)  # Bleu clair
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.3, 0.5)
	mat.emission_energy = 0.5
	frame.material = mat
	
	match direction:
		"north":
			frame.size = Vector3(DOOR_WIDTH + 0.2, DOOR_HEIGHT + 0.1, 0.1)
			frame.position = Vector3(0, DOOR_HEIGHT/2, -ROOM_SIZE/2)
		"south":
			frame.size = Vector3(DOOR_WIDTH + 0.2, DOOR_HEIGHT + 0.1, 0.1)
			frame.position = Vector3(0, DOOR_HEIGHT/2, ROOM_SIZE/2)
		"east":
			frame.size = Vector3(0.1, DOOR_HEIGHT + 0.1, DOOR_WIDTH + 0.2)
			frame.position = Vector3(ROOM_SIZE/2, DOOR_HEIGHT/2, 0)
		"west":
			frame.size = Vector3(0.1, DOOR_HEIGHT + 0.1, DOOR_WIDTH + 0.2)
			frame.position = Vector3(-ROOM_SIZE/2, DOOR_HEIGHT/2, 0)
	
	room.add_child(frame)

func create_enemy_placeholder(room: Node3D, enemy_data: Dictionary):
	"""Crée un placeholder pour l'ennemi"""
	var enemy = CSGCylinder3D.new()
	enemy.radius = 0.3
	enemy.height = 1.5
	enemy.position = Vector3(
		enemy_data.get("pos_x", 0),
		0.75,
		enemy_data.get("pos_y", 0)
	)
	
	var mat = StandardMaterial3D.new()
	var enemy_type = enemy_data.get("type", "unknown")
	
	# Couleur selon le type d'ennemi
	match enemy_type:
		"goblin":
			mat.albedo_color = Color(0.2, 0.6, 0.2)  # Vert
		"skeleton":
			mat.albedo_color = Color(0.8, 0.8, 0.7)  # Blanc cassé
		"boss_skeleton_king":
			mat.albedo_color = Color(0.6, 0.1, 0.1)  # Rouge sombre
			enemy.radius = 0.5  # Plus gros pour le boss
			enemy.height = 2.0
			enemy.position.y = 1.0
		_:
			mat.albedo_color = Color.DARK_RED
	
	enemy.material = mat
	enemy.name = "Enemy_" + enemy_type
	enemy.set_meta("enemy_type", enemy_type)
	
	room.add_child(enemy)

func add_room_type_indicator(room: Node3D, room_type: String):
	"""Ajoute un indicateur visuel flottant pour identifier le type de salle"""
	if room_type == "empty":
		return
	
	var indicator = CSGTorus3D.new()
	indicator.inner_radius = 0.3
	indicator.outer_radius = 0.5
	indicator.position = Vector3(0, 2.5, 0)
	indicator.name = "TypeIndicator"
	
	var mat = StandardMaterial3D.new()
	mat.emission_enabled = true
	
	match room_type:
		"combat":
			mat.albedo_color = Color.RED
			mat.emission = Color.RED
		"treasure":
			mat.albedo_color = Color.GOLD
			mat.emission = Color.GOLD
		"boss":
			mat.albedo_color = Color.DARK_RED
			mat.emission = Color.DARK_RED
			indicator.inner_radius = 0.5
			indicator.outer_radius = 0.8
	
	mat.emission_energy = 1.0
	indicator.material = mat
	
	# Ajoute une rotation pour l'animation
	var anim_script = GDScript.new()
	anim_script.source_code = """
extends CSGTorus3D
func _process(delta):
	rotate_y(delta * 2.0)
"""
	indicator.set_script(anim_script)
	
	room.add_child(indicator)

func create_default_room():
	"""Crée des salles par défaut si pas de JSON"""
	print("⚠️ Création d'une salle par défaut...")
	var default_data = {
		"name": "Niveau par défaut",
		"rooms": [
			{"id": 1, "x": 0, "y": 0, "type": "empty"},
			{"id": 2, "x": 1, "y": 0, "type": "combat", 
			 "enemies": [{"type": "goblin", "pos_x": 2, "pos_y": 0}]},
			{"id": 3, "x": 0, "y": 1, "type": "treasure"}
		],
		"connections": [
			{"from": 1, "to": 2, "direction": "east"},
			{"from": 1, "to": 3, "direction": "north"}
		]
	}
	generate_level(default_data)

# Fonction utilitaire pour obtenir la salle à une position
func get_room_at_position(world_position: Vector3) -> Node3D:
	"""Retourne la salle à une position donnée dans le monde"""
	for room in rooms_container.get_children():
		var room_pos = room.position
		var half_size = ROOM_SIZE / 2.0
		
		if world_position.x >= room_pos.x - half_size and \
		   world_position.x <= room_pos.x + half_size and \
		   world_position.z >= room_pos.z - half_size and \
		   world_position.z <= room_pos.z + half_size:
			return room
	
	return null
