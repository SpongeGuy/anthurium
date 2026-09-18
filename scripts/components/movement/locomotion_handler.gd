extends Component
class_name LocomotionHandler

@export var input: InputComponent
@export var speed: float = 75.0
@export var profile: LocomotionProfile
@export var disabled: bool = false

var velocity: Vector2 = Vector2.ZERO
var override: bool = false

var last_velocity: Vector2 = Vector2.ZERO

func handle_locomotion(delta: float) -> Vector2:
	if disabled:
		velocity = lerp(velocity, Vector2.ZERO, 0.25)
	elif profile:
		last_velocity = velocity
		velocity = profile.move(self, delta)
	return velocity
