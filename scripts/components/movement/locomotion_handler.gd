extends Component
class_name LocomotionHandler

@export var input: InputComponent
@export var speed: float = 500.0
var velocity: Vector2 = Vector2.ZERO

@export var disabled: bool = false
var override: bool = false

func _on_registered() -> void:
	pass # replace with function body

func handle_locomotion(delta: float) -> Vector2:
	if disabled:
		velocity = lerp(velocity, Vector2.ZERO, 0.25)
	else:
		_movement_function(delta)
	return velocity
	
func _movement_function(delta: float) -> void:
	# override this
	pass
