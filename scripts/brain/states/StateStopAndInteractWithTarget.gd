extends BrainState
class_name StateStopAndInteractWithTarget

var radius: float = 16
var target: Entity

var input: InputComponent
var locomotion: LocomotionHandler

var _input_timer: float = 0.0
var input_timer_cooldown: float = 1.0

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	target = brain.get_memory(Brain.Memory.TARGET)
	

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	_input_timer -= delta
	if _input_timer <= 0.0:
		
		
		input.press_interact()
		input.release_interact()
		_input_timer = input_timer_cooldown
		
	if not input.player_controlled:
		_handle_ai_movement(delta)
	
	locomotion.handle_locomotion(delta)
	
func _handle_ai_movement(delta: float) -> void:
	input.set_move_input_direction(Vector2.ZERO)
	

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	if not is_instance_valid(target):
		return &"seek"
	if not SpatialUtil.is_within_distance_of_entity(entity, target, radius):
		return &"seek"
	
	return &""

