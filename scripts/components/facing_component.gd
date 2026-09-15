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


# -------------------------------------------------------------------
# debug
# ----------------------------------------------------------------------------------
@export var debug_draw_facing: bool = false
const DEBUG_LINE_LENGTH: float = 16.0
const DEBUG_LINE_COLOR: Color = Color(0.0, 1.0, 0.0)

func _on_registered() -> void:
	entity.draw.connect(_on_entity_draw)
	
func _process(_delta: float) -> void:
	if debug_draw_facing:
		entity.queue_redraw() 
	
func _on_entity_draw() -> void:
	if not debug_draw_facing:
		return
	entity.draw_line(Vector2.ZERO, _direction * DEBUG_LINE_LENGTH, DEBUG_LINE_COLOR, 2.0)
