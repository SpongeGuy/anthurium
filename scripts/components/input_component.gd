extends Component
class_name InputComponent

# -------------------------------------------------------------
# checks every frame for certain user inputs.
# ------------------------------------------------------------


var move_input_direction: Vector2

var actions: Array[String] = ["primary_action", "secondary_action", "ternary_action", "quaternary_action"]
var just_pressed: Array[bool] = [false, false, false, false]
var hold_time: Array[float] = [0.0, 0.0, 0.0, 0.0]
var is_held: Array[bool] = [false, false, false, false]
var just_released: Array[bool] = [false, false, false, false]

signal input_just_pressed(id: int)
signal input_just_released(id: int, held_time: float)

func _process(delta: float) -> void:
	for id in range(actions.size()):
		if is_held[id]:
			hold_time[id] += delta
		else:
			hold_time[id] = 0	
	

	
func set_move_input_direction(direction: Vector2) -> void:
	move_input_direction = direction
	
func press_action(id: int) -> void:
	just_pressed[id] = true
	is_held[id] = true
	input_just_pressed.emit(id)
	await get_tree().process_frame
	just_pressed[id] = false


func release_action(id: int) -> void:
	just_released[id] = true
	is_held[id] = false
	input_just_released.emit(id, hold_time[id])
	await get_tree().process_frame
	just_released[id] = false
