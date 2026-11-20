class_name StateGhostFlee extends BrainState

const CATCH_UP_SPEED: float = 2.0

var input: InputComponent
var locomotion: LocomotionHandler

var flee_target_position: Vector2 = Vector2.ZERO

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	flee_target_position = SpatialUtil.get_random_offscreen_position(CameraController.camera, RunRng.get_stream("ghost_flee"))

	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	if input.player_controlled:
		locomotion.handle_locomotion(delta)
	else:
		var weight: float = 1.0 - exp(-CATCH_UP_SPEED * delta)
		entity.global_position = lerp(entity.global_position, flee_target_position, weight)

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""

