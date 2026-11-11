extends BrainState
class_name StatePathfindTowardsTarget

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent

var target: Entity

var nearby_radius: float = 30
var is_nearby: bool


func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	
	target = brain.get_memory(Brain.Memory.TARGET)
	
	if navigation.is_navigating():
		navigation.stop_navigation()

func exit() -> void:
	if not is_instance_valid(target):
		return
	brain.set_memory(Brain.Memory.LAST_FOOD_LOCATION, target.global_position)

func physics_process(delta: float) -> void:
	is_nearby = false
	if not input.player_controlled:
		_handle_ai_movement(delta)
	is_nearby = _get_if_nearby()
	locomotion.handle_locomotion(delta)
	
func _handle_ai_movement(delta: float) -> void:
	if not is_instance_valid(target):
		return
	navigation.set_new_pathfinding_location_explicit(target.position)
	input.set_move_input_direction(navigation.get_next_path_direction())
	facing.set_direction_angle(SpatialUtil.get_angle_between_entities(entity, target))
	
	
func _get_if_nearby() -> bool:
	if not is_instance_valid(target):
		return false
	return SpatialUtil.is_within_distance_of_entity(entity, target, nearby_radius)
		

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	if not is_instance_valid(target):
		return &"seek"
	if is_nearby:
		return &"interact"
	return &""
