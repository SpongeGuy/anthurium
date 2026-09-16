extends BrainState
class_name StateWatchThreat

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent

var target: Entity
var radius_to_switch: float = 64

var dist_from_target: float

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	
	if navigation.is_navigating():
		navigation.stop_navigation()
		
	input.set_move_input_direction(Vector2.ZERO)
		
	play_effect(&"on_enter")
	target = brain.get_memory(Brain.Memory.THREAT)
	dist_from_target = INF

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	dist_from_target = SpatialUtil.get_distance_between_entities(entity, target)
	facing.set_direction_angle(SpatialUtil.get_angle_between_entities(entity, target))
	locomotion.handle_locomotion(delta)

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	if dist_from_target < radius_to_switch:
		return &"flee"
	return &""
