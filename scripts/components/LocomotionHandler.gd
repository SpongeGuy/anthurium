extends Component
class_name LocomotionHandler

@export var navigation: NavigationHelper
@export var facing: FacingComponent
@export var input: InputComponent
@export var brain: Brain
@export var max_speed: float = 100.0
@export var speed: float = 40.0
@export var profile: LocomotionProfile
@export var disabled: bool = false
@export var move_timer: float = -1



var _move_timer: float = 0.0

var locked_direction: Vector2 = Vector2.ZERO

var velocity: Vector2 = Vector2.ZERO
var override: bool = false

var unhandled_step: bool = false

var rng: RandomNumberGenerator

signal step

func _on_registered() -> void:
	if not facing:
		facing = entity.get_component(FacingComponent)
	if not input:
		input = entity.get_component(InputComponent)
	if not navigation:
		navigation = entity.get_component(NavigationHelper)
	if not brain:
		brain = entity.get_component(Brain)
		
	rng = RunRng.get_stream(&"entity")
		
	_move_timer = RandomUtil.randomize_float_with_personality(rng, move_timer, 0.5, 1 - brain.get_personality_value(Brain.PERSONALITY.ENERGY), 1.0) if brain else move_timer

func set_speed(value: float) -> void:
	speed = clamp(value, 0.0, max_speed)

var last_velocity: Vector2 = Vector2.ZERO

func handle_locomotion(delta: float) -> Vector2:
	if move_timer > 0:
		_move_timer -= delta
		if _move_timer <= 0.0:
			_move_timer = RandomUtil.randomize_float_with_personality(rng, move_timer, 0.5, 1 - brain.get_personality_value(Brain.PERSONALITY.ENERGY), 1.0)
			unhandled_step = true
	if disabled:
		velocity = lerp(velocity, Vector2.ZERO, delta * 5)
	elif profile:
		last_velocity = velocity
		if unhandled_step:
			profile._handle_step(self)
		velocity = profile.move(self, delta)
	return velocity

