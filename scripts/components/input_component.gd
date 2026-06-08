extends Component
class_name InputComponent

# -------------------------------------------------------------
# checks every frame for certain user inputs.
# these functions are either called from PlayerManager, a singleton
# or they are called from BehaviorStates.
# ------------------------------------------------------------


var move_input_direction: Vector2

# ability actions
var actions: Array[String] = ["action_primary", "action_secondary", "action_ternary", "action_quaternary"]
var just_pressed: Array[bool] = [false, false, false, false]
var hold_time: Array[float] = [0.0, 0.0, 0.0, 0.0]
var is_held: Array[bool] = [false, false, false, false]
var just_released: Array[bool] = [false, false, false, false]

# action modifier
var modifier: bool = false

# interact action
var interact_just_pressed: bool = false
var interact_hold_time: float = 0.0
var interact_is_held: bool = false
var interact_just_released: bool = false


signal input_just_pressed(id: int)
signal input_just_released(id: int, held_time: float)
signal modifier_just_pressed
signal modifier_just_released

var player_controlled: bool = false

func _process(delta: float) -> void:
	for id in range(actions.size()):
		if is_held[id]:
			hold_time[id] += delta
		else:
			hold_time[id] = 0	
	
func press_action(id: int) -> void:
	if is_held[id] == true:
		return
	just_pressed[id] = true
	is_held[id] = true
	input_just_pressed.emit(id)
	await get_tree().process_frame
	just_pressed[id] = false

func release_action(id: int) -> void:
	if is_held[id] == false:
		return
	just_released[id] = true
	is_held[id] = false
	input_just_released.emit(id, hold_time[id])
	await get_tree().process_frame
	just_released[id] = false

func press_modifier() -> void:
	modifier = true
	modifier_just_pressed.emit()
	
func release_modifier() -> void:
	modifier = false
	modifier_just_released.emit()

func press_interact() -> void:
	if interact_is_held == true:
		return
	interact_just_pressed = true
	interact_is_held = true
	await get_tree().process_frame
	interact_just_pressed = false
	
func release_interact() -> void:
	if interact_is_held == false:
		return
	interact_just_released = true
	interact_is_held = false
	await get_tree().process_frame
	interact_just_released = false
	
