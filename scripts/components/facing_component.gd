extends Component
class_name FacingComponent

## update direction by calling set_direction_vector() in a behavior state.

var _direction: Vector2 = Vector2.ZERO

var _old_direction: Vector2 = Vector2.ZERO

func set_direction_vector(new_direction: Vector2) -> void:
	if new_direction == Vector2.ZERO:
		return
	_old_direction = _direction
	_direction = new_direction.normalized()
	
func set_direction_angle(new_direction: float) -> void:
	_old_direction = _direction
	_direction = Vector2.from_angle(new_direction)
	
func get_direction() -> Vector2:
	return _direction
	
func get_direction_angle() -> float:
	return _direction.angle()

