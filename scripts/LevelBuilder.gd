extends Node3D
class_name LevelBuilder

var room_size = 10.0  # Taille d'une salle
var rooms_container: Node3D

func _ready():
	rooms_container = Node3D.new()
	rooms_container.name = "Rooms"
	add_child(rooms_container)
	
	# Charge le niveau de test
	load_level("res://data/levels/test_level.json")

func load_level(json_path: String):
	if not FileAccess.file_exists(json_path):
		print("Erreur : Fichier non trouvé - ", json_path)
		create_default_room()
		return
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Erreur parsing JSON : ", json.get_error_message())
		return
	
	var level_data = json.data
	generate_level(level_data)

func generate_level(data: Dictionary):
	# Nettoie les salles existantes
	for child in rooms_container.get_children():
		child.queue_free()
	
	# Génère les nouvelles salles
	if data.has("rooms"):
		for room_data in data["rooms"]:
			create_room(room_data)
	
	print("Niveau généré : ", data["rooms"].size(), " salles")

func create_room(room_data: Dictionary):
	# Position de la salle
	var x = room_data.get("x", 0) * room_size
	var z = room_data.get("y", 0) * room_size  # Y dans JSON = Z dans Godot 3D
	var room_type = room_data.get("type", "empty")
	
	# Crée le conteneur de la salle
	var room = Node3D.new()
	room.position = Vector3(x, 0, z)
	room.name = "Room_" + str(room_data.get("id", "unknown"))
	
	# Sol de la salle
	var floor = CSGBox3D.new()
	floor.size = Vector3(room_size - 0.5, 0.2, room_size - 0.5)
	floor.position.y = -0.1
	floor.use_collision = true
	
	# Matériau selon le type
	var material = StandardMaterial3D.new()
	match room_type:
		"combat":
			material.albedo_color = Color.RED
		"treasure":
			material.albedo_color = Color.GOLD
		"boss":
			material.albedo_color = Color.DARK_RED
		_:
			material.albedo_color = Color.GRAY
	
	floor.material = material
	room.add_child(floor)
	
	# Murs
	create_walls(room, room_data)
	
	# Ajoute les ennemis si définis
	if room_data.has("enemies"):
		for enemy_data in room_data["enemies"]:
			create_enemy_placeholder(room, enemy_data)
	
	rooms_container.add_child(room)

func create_walls(room: Node3D, room_data: Dictionary):
	var wall_height = 3.0
	var wall_thickness = 0.2
	var gap_size = 2.0  # Taille de l'ouverture pour les portes
	
	# Récupère les connexions si elles existent
	var has_north = false
	var has_south = false
	var has_east = false
	var has_west = false
	
	# Pour l'instant, on met des ouvertures partout où il y a des salles adjacentes
	var x = room_data.get("x", 0)
	var y = room_data.get("y", 0)
	
	# Mur Nord (avec ou sans ouverture)
	if not has_north:
		var wall_n = CSGBox3D.new()
		wall_n.size = Vector3(room_size, wall_height, wall_thickness)
		wall_n.position = Vector3(0, wall_height/2, -room_size/2)
		wall_n.use_collision = true
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		wall_n.material = mat
		room.add_child(wall_n)
	
	# Mur Sud
	if not has_south:
		var wall_s = CSGBox3D.new()
		wall_s.size = Vector3(room_size, wall_height, wall_thickness)
		wall_s.position = Vector3(0, wall_height/2, room_size/2)
		wall_s.use_collision = true
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		wall_s.material = mat
		room.add_child(wall_s)
	
	# Mur Est
	if not has_east:
		var wall_e = CSGBox3D.new()
		wall_e.size = Vector3(wall_thickness, wall_height, room_size)
		wall_e.position = Vector3(room_size/2, wall_height/2, 0)
		wall_e.use_collision = true
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		wall_e.material = mat
		room.add_child(wall_e)
	
	# Mur Ouest
	if not has_west:
		var wall_w = CSGBox3D.new()
		wall_w.size = Vector3(wall_thickness, wall_height, room_size)
		wall_w.position = Vector3(-room_size/2, wall_height/2, 0)
		wall_w.use_collision = true
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		wall_w.material = mat
		room.add_child(wall_w)

func create_enemy_placeholder(room: Node3D, enemy_data: Dictionary):
	# Placeholder pour l'ennemi
	var enemy = CSGCylinder3D.new()
	enemy.radius = 0.3
	enemy.height = 1.5
	enemy.position = Vector3(
		enemy_data.get("pos_x", 0),
		0.75,
		enemy_data.get("pos_y", 0)
	)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color.DARK_RED
	enemy.material = mat
	enemy.name = "Enemy_" + enemy_data.get("type", "unknown")
	
	room.add_child(enemy)

func create_default_room():
	print("Création d'une salle par défaut...")
	var default_data = {
		"rooms": [
			{"id": 1, "x": 0, "y": 0, "type": "empty"},
			{"id": 2, "x": 1, "y": 0, "type": "combat", "enemies": [{"pos_x": 2, "pos_y": 0}]},
			{"id": 3, "x": 0, "y": 1, "type": "treasure"}
		]
	}
	generate_level(default_data)
