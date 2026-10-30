extends Node

# DeviceManager autoload
##
## Lowest layer of the player stack. Knows which physical input devices exist and which
## player slot each one occupies, and builds the per-slot InputMap actions ("p0_up", "p0_start", ...).
## It knows nothing about game state, entities or UI.
##
## Joypads claim the lowest free slot as soon as they are plugged in (up to [constant MAX_PLAYERS];
## extra pads wait until a slot frees up).
## The keyboard does NOT hold a slot by default. [PlayerManager] calls [method claim_keyboard] when the
## keyboard join key is pressed, and [method release_slot] when that slot goes back to idle.
 
signal slot_connected(slot: int, device: int)
signal slot_disconnected(slot: int)
 
const MAX_PLAYERS: int = 2
const KEYBOARD_DEVICE: int = -1
const KEYBOARD_JOIN_ACTION: StringName = &"kb_join"
 
const ACTIONS: Array[String] = ["up", "left", "down", "right", "action_primary", "action_secondary", "action_ternary", "action_quaternary", "action_interact", "start", "select"]

const JOY_BUTTONS: Dictionary = {
	"action_primary": JOY_BUTTON_A,
	"action_secondary": JOY_BUTTON_B,
	"action_ternary": JOY_BUTTON_X,
	"action_quaternary": JOY_BUTTON_Y,
	"action_interact": JOY_BUTTON_RIGHT_SHOULDER,
	"start": JOY_BUTTON_START,
	"select": JOY_BUTTON_BACK,
	"up": JOY_BUTTON_DPAD_UP,
	"left": JOY_BUTTON_DPAD_LEFT,
	"down": JOY_BUTTON_DPAD_DOWN,
	"right": JOY_BUTTON_DPAD_RIGHT,
}
 
const JOY_STICK: Dictionary = {
	"up": [JOY_AXIS_LEFT_Y, -1.0],
	"left": [JOY_AXIS_LEFT_X, -1.0],
	"down": [JOY_AXIS_LEFT_Y, 1.0],
	"right": [JOY_AXIS_LEFT_X, 1.0],
}
 
# NOTE: interact is Q (not E) because AppController has a debug KEY_E check.
const KEYBOARD_KEYS: Dictionary = {
	"up": [KEY_W, KEY_UP],
	"left": [KEY_A, KEY_LEFT],
	"down": [KEY_S, KEY_DOWN],
	"right": [KEY_D, KEY_RIGHT],
	"action_primary": [KEY_Z],
	"action_secondary": [KEY_X],
	"action_ternary": [KEY_C],
	"action_quaternary": [KEY_V],
	"action_interact": [KEY_Q],
	"start": [KEY_ENTER, KEY_KP_ENTER],
	"select": [KEY_BACKSPACE],
}

## slot -> device id ([constant KEYBOARD_DEVICE] for the keyboard)
var player_devices: Dictionary[int, int] = {}
var _waiting_joypads: Array[int] = []



func _ready() -> void:
	_build_keyboard_join_action()
	Input.joy_connection_changed.connect(_on_joy_changed)
	for device in Input.get_connected_joypads():
		_on_joy_changed(device, true)

# ----------------------------------------------
# queries
# ----------------------------------------------
 
func has_keyboard() -> bool:
	return player_devices.values().has(KEYBOARD_DEVICE)
 
func get_keyboard_slot() -> int:
	var slot: Variant = player_devices.find_key(KEYBOARD_DEVICE)
	return -1 if slot == null else slot
 
func is_keyboard_slot(slot: int) -> bool:
	return player_devices.get(slot, -2) == KEYBOARD_DEVICE
 
func get_free_slot() -> int:
	for slot in MAX_PLAYERS:
		if not player_devices.has(slot):
			return slot
	return -1

# ----------------------------------------------
# claiming / releasing
# ----------------------------------------------
 
## Gives the keyboard the lowest free slot. Returns the slot, or -1 if all slots are taken.
func claim_keyboard() -> int:
	if has_keyboard():
		return get_keyboard_slot()
	return _claim(KEYBOARD_DEVICE)
 
## Frees [param slot] and removes its InputMap actions. Waiting joypads may take the slot.
func release_slot(slot: int) -> void:
	if not player_devices.has(slot):
		return
	player_devices.erase(slot)
	_erase_actions(slot)
	slot_disconnected.emit(slot)
	_assign_waiting_joypads()
 
func _claim(device: int) -> int:
	var slot: int = get_free_slot()
	if slot < 0:
		return -1
	player_devices[slot] = device
	_build_actions(slot, device)
	slot_connected.emit(slot, device)
	return slot
 
func _on_joy_changed(device: int, connected: bool) -> void:
	if connected:
		if player_devices.values().has(device) or _waiting_joypads.has(device):
			return
		if _claim(device) < 0:
			_waiting_joypads.append(device)
	else:
		_waiting_joypads.erase(device)
		var slot: Variant = player_devices.find_key(device)
		if slot != null:
			release_slot(slot)
 
func _assign_waiting_joypads() -> void:
	while not _waiting_joypads.is_empty() and get_free_slot() >= 0:
		_claim(_waiting_joypads.pop_front())





# ----------------------------------------------
# InputMap construction
# ----------------------------------------------
 
func _build_keyboard_join_action() -> void:
	if InputMap.has_action(KEYBOARD_JOIN_ACTION):
		InputMap.erase_action(KEYBOARD_JOIN_ACTION)
	InputMap.add_action(KEYBOARD_JOIN_ACTION)
	for key: int in KEYBOARD_KEYS["start"]:
		_add_key(KEYBOARD_JOIN_ACTION, key)
 
func _build_actions(slot: int, device: int) -> void:
	_erase_actions(slot)
	for a in ACTIONS:
		InputMap.add_action("p%d_%s" % [slot, a], 0.2)
 
	if device == KEYBOARD_DEVICE:
		for action: String in KEYBOARD_KEYS:
			for key: int in KEYBOARD_KEYS[action]:
				_add_key("p%d_%s" % [slot, action], key)
	else:
		for action: String in JOY_STICK:
			var spec: Array = JOY_STICK[action]
			_add_axis("p%d_%s" % [slot, action], spec[0], spec[1], device)
		for action: String in JOY_BUTTONS:
			_add_button("p%d_%s" % [slot, action], JOY_BUTTONS[action], device)
 
func _erase_actions(slot: int) -> void:
	for a in ACTIONS:
		var name: String = "p%d_%s" % [slot, a]
		if InputMap.has_action(name):
			InputMap.erase_action(name)
 
func _add_axis(action: String, axis: int, value: float, device: int) -> void:
	var ev: InputEventJoypadMotion = InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	ev.device = device
	InputMap.action_add_event(action, ev)
 
func _add_button(action: String, button: int, device: int) -> void:
	var ev: InputEventJoypadButton = InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = device
	InputMap.action_add_event(action, ev)
 
func _add_key(action: StringName, key: int) -> void:
	var ev: InputEventKey = InputEventKey.new()
	ev.physical_keycode = key
	InputMap.action_add_event(action, ev)
