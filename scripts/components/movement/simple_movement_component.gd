extends MovementComponent
class_name SimpleMovementComponent


func movement_function(delta: float) -> void:
	velocity = input.move_input_direction * max_speed
