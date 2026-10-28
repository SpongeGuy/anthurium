extends Node

var player_devices: Dictionary = {}

const ACTIONS: Array[String] = ["up", "left", "down", "right", "action_primary", "action_secondary", "action_ternary", "action_quaternary", "action_interact", "start", "select"]

signal slot_connected(slot: int)
signal slot_disconnected(slot: int)
const MAX_PLAYERS: int = 4

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_changed)
	for device in Input.get_connected_joypads():
		_on_joy_changed(device, true)

func _on_joy_changed(device: int, connected: bool) -> void:
	if connected:
		if device in player_devices.values():
			return
		var slot: int = 0
		while player_devices.has(slot):
			slot += 1
		assign_device(slot, device)
		slot_connected.emit(slot)
	else:
		var slot = player_devices.find_key(device)
		if slot != null:
			player_devices.erase(slot)
			slot_disconnected.emit(slot)
	

func assign_device(player: int, device: int) -> void:
	
	player_devices[player] = device
	_build_actions(player, device)

func _build_actions(player: int, device: int) -> void:
	for a in ACTIONS:
		var name: String = "p%d_%s" % [player, a]
		if InputMap.has_action(name):
			InputMap.erase_action(name)
		InputMap.add_action(name, 0.2)
	
	_axis(player, "up", JoyAxis.JOY_AXIS_LEFT_Y, -1.0, device)
	_axis(player, "left", JoyAxis.JOY_AXIS_LEFT_X, -1.0, device)
	_axis(player, "down", JoyAxis.JOY_AXIS_LEFT_Y, 1.0, device)
	_axis(player, "right", JoyAxis.JOY_AXIS_LEFT_X, 1.0, device)
	
	_button(player, "action_primary", JoyButton.JOY_BUTTON_A, device)
	_button(player, "action_secondary", JoyButton.JOY_BUTTON_B, device)
	_button(player, "action_ternary", JoyButton.JOY_BUTTON_X, device)
	_button(player, "action_quaternary", JoyButton.JOY_BUTTON_Y, device)
	_button(player, "action_interact", JoyButton.JOY_BUTTON_RIGHT_SHOULDER, device)
	_button(player, "start", JoyButton.JOY_BUTTON_START, device)
	_button(player, "select", JoyButton.JOY_BUTTON_BACK, device)
	
	_button(player, "up", JoyButton.JOY_BUTTON_DPAD_UP, device)
	_button(player, "left", JoyButton.JOY_BUTTON_DPAD_LEFT, device)
	_button(player, "down", JoyButton.JOY_BUTTON_DPAD_DOWN, device)
	_button(player, "right", JoyButton.JOY_BUTTON_DPAD_RIGHT, device)
	

func _axis(player: int, action: String, axis: JoyAxis, value: float, device: int) -> void:
	var ev: InputEventJoypadMotion = InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	ev.device = device
	InputMap.action_add_event("p%d_%s" % [player, action], ev)

func _button(player: int, action: String, button: JoyButton, device: int) -> void:
	var ev: InputEventJoypadButton = InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = device
	InputMap.action_add_event("p%d_%s" % [player, action], ev)
