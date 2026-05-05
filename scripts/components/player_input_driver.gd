extends Component
class_name PlayerInputDriver

@export var input: InputComponent



func _process(_delta: float) -> void:
	for id in range(input.actions.size()):
		if Input.is_action_just_pressed(input.actions[id]):
			input.press_action(id)
		if Input.is_action_just_released(input.actions[id]):
			input.release_action(id)
			
	input.move_input_direction = Input.get_vector("west", "east", "north", "south")

