extends BehaviorState
class_name IdlersState

@export var input: InputComponent

func enter() -> void:
	pass
	
func update(delta: float) -> void:
	if input:
		input.move_input_direction = Vector2.ZERO
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	pass
