extends Component
class_name JumpOnTimerComponent


@export var jump_velocity: float = 30.0
@export var timer: float = 3

var _timer: float

## called once when the state machine does its initial switch to this state
func _ready() -> void:
	_timer = timer
	
## called every frame while this state is active
func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		entity.jump(jump_velocity, false)
		_timer = timer + (randf() * TAU)
