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
var i_just_pressed: bool = false
var i_hold_time: float = 0.0
var i_is_held: bool = false
var i_just_released: bool = false


signal input_just_pressed(id: int)
signal input_just_released(id: int, held_time: float)
signal modifier_just_pressed
signal modifier_just_released
signal interact_just_pressed
signal interact_just_released

var player_controlled: bool = false

func _process(delta: float) -> void:
	for id in range(actions.size()):
		just_pressed[id] = false
		just_released[id] = false
	i_just_pressed = false
	i_just_released = false
	
	for id in range(actions.size()):
		if is_held[id]:
			hold_time[id] += delta
		else:
			hold_time[id] = 0	
		
	if debug_draw_input_direction:
		entity.queue_redraw() 
	
func press_action(id: int) -> void:
	if is_held[id] == true:
		return
	just_pressed[id] = true
	is_held[id] = true
	input_just_pressed.emit(id)

func release_action(id: int) -> void:
	if is_held[id] == false:
		return
	just_released[id] = true
	is_held[id] = false
	input_just_released.emit(id, hold_time[id])

func press_modifier() -> void:
	modifier = true
	modifier_just_pressed.emit()
	
func release_modifier() -> void:
	modifier = false
	modifier_just_released.emit()

func press_interact() -> void:
	if i_is_held == true:
		return
	i_just_pressed = true
	i_is_held = true
	interact_just_pressed.emit()
	
func release_interact() -> void:
	if i_is_held == false:
		return
	i_just_released = true
	i_is_held = false
	interact_just_released.emit()
	
func set_move_input_direction(direction: Vector2) -> void:
	move_input_direction = direction


# -------------------------------------------------------------------
# debug
# ----------------------------------------------------------------------------------
@export var debug_draw_input_direction: bool = false
const DEBUG_LINE_LENGTH: float = 16.0
const DEBUG_LINE_COLOR: Color = Color(0.16, 0.463, 0.961, 1.0)

func _on_registered() -> void:
	entity.draw.connect(_on_entity_draw)
	

func _on_entity_draw() -> void:
	if not debug_draw_input_direction:
		return
	entity.draw_line(Vector2.ZERO, move_input_direction * DEBUG_LINE_LENGTH, DEBUG_LINE_COLOR, 2.0)
