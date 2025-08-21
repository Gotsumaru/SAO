extends Camera3D

var speed = 20.0  # Augmenté pour tests
var mouse_sensitivity = 0.005
var overview_mode = true  # Mode vue d'ensemble pour tests

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Position initiale pour vue d'ensemble
	if overview_mode:
		position = Vector3(10, 20, 10)
		look_at(Vector3(10, 0, 0), Vector3.UP)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_object_local(Vector3(1, 0, 0), -event.relative.y * mouse_sensitivity)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Touches de test
	if event.is_action_pressed("ui_page_up"):  # Page Up
		position.y += 5
		print("📷 Hauteur caméra: ", position.y)
	
	if event.is_action_pressed("ui_page_down"):  # Page Down
		position.y -= 5
		print("📷 Hauteur caméra: ", position.y)
	
	# Bascule vue d'ensemble
	if event.is_action_pressed("ui_accept"):  # Entrée
		overview_mode = !overview_mode
		if overview_mode:
			position = Vector3(10, 20, 10)
			rotation = Vector3(-0.5, 0, 0)
			print("🎥 Mode vue d'ensemble activé")
		else:
			position = Vector3(0, 2, 5)
			rotation = Vector3(0, 0, 0)
			print("🎮 Mode jeu activé")

func _process(delta):
	var input_vector = Vector3()
	
	# Mouvements basiques
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector -= transform.basis.z
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector += transform.basis.z
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector -= transform.basis.x
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector += transform.basis.x
	
	# Montée/Descente avec Q et E
	if Input.is_key_pressed(KEY_Q):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_E):
		input_vector.y += 1
	
	position += input_vector.normalized() * speed * delta
	
	# Affichage debug de la position
	if Engine.get_process_frames() % 60 == 0:  # Toutes les secondes
		var level_builder = get_node("/root/World")
		if level_builder and level_builder.has_method("get_room_at_position"):
			var current_room = level_builder.get_room_at_position(position)
			if current_room:
				print("📍 Dans la salle: ", current_room.name)
