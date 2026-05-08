extends Component
class_name LocomotionHandler

@export var input: InputComponent
@export var speed: float = 500.0
var velocity: Vector2 = Vector2.ZERO

@export var disabled: bool = false

func _on_registered() -> void:
	pass # replace with function body

func movement_function(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if disabled:
		velocity = Vector2.ZERO
	entity.velocity += velocity
