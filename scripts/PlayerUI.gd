extends Control

@onready var health_bar: ProgressBar = $StatsContainer/HealthBar
@onready var stamina_bar: ProgressBar = $StatsContainer/StaminaBar
@onready var health_label: Label = $StatsContainer/HealthLabel
@onready var stamina_label: Label = $StatsContainer/StaminaLabel
@onready var state_label: Label = $InfoContainer/StateLabel
@onready var room_label: Label = $InfoContainer/RoomLabel

var player: Player

func _ready():
	# Trouve le joueur
	player = get_node("/root/World/Player")
	
	# Configure les barres
	if health_bar:
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
	
	if stamina_bar:
		stamina_bar.max_value = player.max_stamina
		stamina_bar.value = player.stamina

func _process(_delta):
	if not player:
		return
	
	# Update les barres
	if health_bar:
		health_bar.value = player.current_health
		health_label.text = str(player.current_health) + "/" + str(player.max_health)
	
	if stamina_bar:
		stamina_bar.value = player.stamina
		stamina_label.text = str(int(player.stamina)) + "%"
	
	# Update les infos
	if state_label:
		state_label.text = "État: " + Player.State.keys()[player.current_state]
	
	if room_label:
		var room = player.get_current_room()
		if room:
			var room_type = room.get_meta("room_type", "unknown")
			room_label.text = "Salle: " + room.name + " (" + room_type + ")"
		else:
			room_label.text = "Salle: Aucune"
