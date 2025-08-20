extends Camera3D

var speed = 10.0
var mouse_sensitivity = 0.005

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_object_local(Vector3(1, 0, 0), -event.relative.y * mouse_sensitivity)
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	var input_vector = Vector3()
	
	if Input.is_action_pressed("ui_up"):
		input_vector -= transform.basis.z
	if Input.is_action_pressed("ui_down"):
		input_vector += transform.basis.z
	if Input.is_action_pressed("ui_left"):
		input_vector -= transform.basis.x
	if Input.is_action_pressed("ui_right"):
		input_vector += transform.basis.x
	
	position += input_vector.normalized() * speed * delta
