extends Node

const MOUSE_NAME_TO_BUTTON: Dictionary = {
	"LEFT": MOUSE_BUTTON_LEFT,
	"RIGHT": MOUSE_BUTTON_RIGHT,
	"MIDDLE": MOUSE_BUTTON_MIDDLE,
	"WHEEL_UP": MOUSE_BUTTON_WHEEL_UP,
	"WHEEL_DOWN": MOUSE_BUTTON_WHEEL_DOWN
}

const JOY_BUTTON_NAME_TO_ID: Dictionary = {
	"A": JOY_BUTTON_A,
	"B": JOY_BUTTON_B,
	"X": JOY_BUTTON_X,
	"Y": JOY_BUTTON_Y,
	"LB": JOY_BUTTON_LEFT_SHOULDER,
	"RB": JOY_BUTTON_RIGHT_SHOULDER,
	"BACK": JOY_BUTTON_BACK,
	"START": JOY_BUTTON_START,
	"L3": JOY_BUTTON_LEFT_STICK,
	"R3": JOY_BUTTON_RIGHT_STICK
}

const JOY_AXIS_NAME_TO_ID: Dictionary = {
	"LEFT_X": JOY_AXIS_LEFT_X,
	"LEFT_Y": JOY_AXIS_LEFT_Y,
	"RIGHT_X": JOY_AXIS_RIGHT_X,
	"RIGHT_Y": JOY_AXIS_RIGHT_Y,
	"TRIGGER_LEFT": JOY_AXIS_TRIGGER_LEFT,
	"TRIGGER_RIGHT": JOY_AXIS_TRIGGER_RIGHT
}

@export_file("*.json") var input_json_path: String = "res://data/inputs.json"

func _ready() -> void:
	_load_from_json(input_json_path)

func _load_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		push_warning("InputLoader: fichier introuvable: %s" % path)
		return

	var txt: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(txt)
	if not (parsed is Dictionary) or not (parsed as Dictionary).has("actions"):
		push_warning("InputLoader: JSON invalide (clé 'actions' manquante)")
		return

	# Nettoyage des events
	for a: StringName in InputMap.get_actions():
		for e: InputEvent in InputMap.action_get_events(a):
			InputMap.action_erase_event(a, e)

	for raw in (parsed as Dictionary)["actions"]:
		if not (raw is Dictionary):
			continue
		var action_dict: Dictionary = raw as Dictionary

		var action_name_v: Variant = action_dict.get("name", "")
		if typeof(action_name_v) != TYPE_STRING:
			continue
		var action_name: String = String(action_name_v)
		if action_name.is_empty():
			continue

		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

		if action_dict.has("deadzone"):
			InputMap.action_set_deadzone(action_name, float(action_dict["deadzone"]))

		var events_v: Variant = action_dict.get("events", [])
		if not (events_v is Array):
			continue
		for e_raw in (events_v as Array):
			if not (e_raw is Dictionary):
				continue
			var ev: InputEvent = _event_from_json(e_raw as Dictionary)
			if ev:
				InputMap.action_add_event(action_name, ev)

	print("InputLoader: actions chargées -> ", InputMap.get_actions().size())

func _event_from_json(e: Dictionary) -> InputEvent:
	var t: String = String(e.get("type", "")).to_lower()
	match t:
		"key":          return _make_key_event(String(e.get("key", "")))
		"mouse_button": return _make_mouse_event(String(e.get("button", "")))
		"joy_button":   return _make_joy_button_event(String(e.get("button", "")))
		"joy_axis":     return _make_joy_axis_event(String(e.get("axis", "")), float(e.get("value", 0.0)))
		_:              push_warning("InputLoader: type inconnu: %s" % t); return null

func _make_key_event(key_name: String) -> InputEventKey:
	if key_name.is_empty(): return null
	var ev := InputEventKey.new()
	ev.keycode = OS.find_keycode_from_string(key_name)
	if ev.keycode == 0:
		push_warning("InputLoader: touche inconnue '%s'" % key_name)
	return ev

func _make_mouse_event(name: String) -> InputEventMouseButton:
	var upper := name.strip_edges().to_upper()
	if not MOUSE_NAME_TO_BUTTON.has(upper):
		push_warning("InputLoader: bouton souris inconnu '%s'" % name)
		return null
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_NAME_TO_BUTTON[upper]   # pas de cast
	return ev

func _make_joy_button_event(button_name: String) -> InputEventJoypadButton:
	var upper := button_name.strip_edges().to_upper()
	if not JOY_BUTTON_NAME_TO_ID.has(upper):
		push_warning("InputLoader: bouton manette inconnu '%s'" % button_name)
		return null
	var ev := InputEventJoypadButton.new()
	ev.button_index = JOY_BUTTON_NAME_TO_ID[upper]  # pas de cast
	return ev

func _make_joy_axis_event(axis_name: String, value: float) -> InputEventJoypadMotion:
	var upper := axis_name.strip_edges().to_upper()
	if not JOY_AXIS_NAME_TO_ID.has(upper):
		push_warning("InputLoader: axe manette inconnu '%s'" % axis_name)
		return null
	var ev := InputEventJoypadMotion.new()
	ev.axis = JOY_AXIS_NAME_TO_ID[upper]            # pas de cast
	ev.axis_value = clamp(value, -1.0, 1.0)
	return ev
