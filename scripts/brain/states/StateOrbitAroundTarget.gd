class_name StateOrbitAroundTarget
extends BrainState

const ARRIVE_DISTANCE: float = 4.0

var input: InputComponent
var facing: FacingComponent
var locomotion: LocomotionHandler


var rng: RandomNumberGenerator
var radius: float = 25
var orbit_point: Vector2
var orbit_speed: float = 1.5 # radians per second
var orbit_direction: float = 1.0
var target_position: Vector2

var _angle: float = 0
var _elapsed: float = 0

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	input = entity.get_component(InputComponent)
	facing = entity.get_component(FacingComponent)
	locomotion = entity.get_component(LocomotionHandler)

	rng = RunRng.get_stream("entity")
	_angle = rng.randf_range(0, 2* PI)

func exit() -> void:
	input.set_move_input_direction(Vector2.ZERO)	

func physics_process(delta: float) -> void:
	var target: Vector2 = brain.get_memory(Brain.Memory.TARGET)
	if target == null:
		return
	orbit_point = target


	_elapsed += delta
	_angle += orbit_direction * orbit_speed * delta


	if not input.player_controlled:
		handle_ai_movement(delta)
	
	locomotion.handle_locomotion(delta)

func handle_ai_movement(_delta: float) -> void:
	var desired: Vector2 = orbit_point + Vector2.from_angle(_angle) * radius
	var to_desired: Vector2 = desired - entity.global_position

	var direction: Vector2 = Vector2.ZERO
	if to_desired.length() > ARRIVE_DISTANCE:
		direction = to_desired.normalized()
	input.set_move_input_direction(direction)
	# face target while orbiting
	facing.set_direction_vector((orbit_point - entity.global_position).normalized())
	
## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""

