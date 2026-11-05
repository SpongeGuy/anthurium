class_name StateOrbitAroundMapCenter
extends BrainState

const ARRIVE_DISTANCE: float = 4.0
const CATCH_UP_SPEED: float = 6.0


var input: InputComponent
var facing: FacingComponent
var locomotion: LocomotionHandler

var rng: RandomNumberGenerator
var radii: Vector2 = Vector2(25, 25)
var orbit_point: Vector2
var orbit_speed: float = 1.5 # radians per second
var orbit_direction: float = 1.0
var target_position: Vector2
var screen_fill: float = 0.6

var _float_time: float = 0
var _unique_float_value: float = 0


var _angle: float = 0

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	input = entity.get_component(InputComponent)
	facing = entity.get_component(FacingComponent)
	locomotion = entity.get_component(LocomotionHandler)

	rng = RunRng.get_stream("entity")
	orbit_point = WorldGrid.tile_to_world(WorldGrid.get_center())
	_update_radii()

	var offset: Vector2 = entity.global_position - orbit_point
	if offset.length() > 0.01:
		# undo the ellipse stretch so the angle matches the parametric angle.
		_angle = Vector2(offset.x / radii.x, offset.y / radii.y).angle()
	else:
		_angle = rng.randf_range(0, TAU)

	_unique_float_value = rng.randf_range(0.8, 1.5)


func exit() -> void:
	input.set_move_input_direction(Vector2.ZERO)

func physics_process(delta: float) -> void:
	orbit_point = WorldGrid.tile_to_world(WorldGrid.get_center())
	_update_radii()  
	_angle += orbit_direction * orbit_speed * delta
	_float_time += delta * _unique_float_value * 5

	if input.player_controlled:
		locomotion.handle_locomotion(delta)
		return

	entity.set_z_value(5 + sin(_float_time))

	var desired: Vector2 = _ellipse_point(_angle)
	var weight: float = 1.0 - exp(-CATCH_UP_SPEED * delta)
	entity.global_position = lerp(entity.global_position, desired, weight)

func handle_ai_movement(_delta: float) -> void:
	var desired: Vector2 = _ellipse_point(_angle)
	var to_desired: Vector2 = desired - entity.global_position

	var direction: Vector2 = Vector2.ZERO
	if to_desired.length() > ARRIVE_DISTANCE:
		direction = to_desired.normalized()
	input.set_move_input_direction(direction)
	facing.set_direction_vector((orbit_point - entity.global_position).normalized())

func _update_radii() -> void:
	var view_size: Vector2 = Vector2(AppController.main_viewport.size)
	radii = view_size * 0.5 * screen_fill

func _ellipse_point(angle: float) -> Vector2:
	return orbit_point + Vector2(cos(angle) * radii.x, sin(angle) * radii.y)

## return the StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""
