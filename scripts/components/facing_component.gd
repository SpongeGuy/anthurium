extends Component
class_name FacingComponent

var _direction: Vector2 = Vector2.ZERO

var _old_direction: Vector2 = Vector2.ZERO

signal changed_direction(old_direction, new_direction)

func change_direction(new_direction: Vector2) -> void:
	if new_direction == Vector2.ZERO:
		return
	_old_direction = _direction
	_direction = new_direction
	_get_direction_change(_old_direction, _direction)
	
func get_direction() -> Vector2:
	return _direction.normalized()
	
func get_direction_angle() -> float:
	return _direction.angle()
	
func _get_direction_change(old_direction: Vector2, new_direction: Vector2) -> void:
	var x_sign_changed = sign(old_direction.x) != sign(new_direction.x) and old_direction.x != 0 and new_direction.x != 0
	var y_sign_changed = sign(old_direction.y) != sign(new_direction.y) and new_direction.y != 0 and new_direction.y != 0
	if x_sign_changed or y_sign_changed:
		changed_direction.emit(old_direction, new_direction)
