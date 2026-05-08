extends LocomotionHandler
class_name NormalLocomotionHandler


func _on_registered() -> void:
	pass # replace with function body


func movement_function(delta: float) -> void:
	velocity = speed * input.move_input_direction
