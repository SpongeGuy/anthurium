extends LocomotionHandler
class_name NormalLocomotionHandler

func _movement_function(delta: float) -> void:
	velocity = speed * input.move_input_direction
