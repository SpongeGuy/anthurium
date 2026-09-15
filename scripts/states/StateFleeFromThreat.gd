extends BrainState
class_name StateFleeFromThreat

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent

var min_radius: float = 5
var max_radius: float = 25

var target: Entity

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	
	if navigation.is_navigating():
		navigation.stop_navigation()
		
	target = brain.get_memory(Brain.Memory.THREAT)

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	facing.set_direction_angle(SpatialUtil.get_angle_between_entities(entity, target))
	if not input.player_controlled:
		_handle_ai_movement()
	locomotion.handle_locomotion(delta)
	
func _handle_ai_movement() -> void:
	var angle: float = SpatialUtil.opposite_angle(facing.get_direction_angle())
	if not navigation.is_navigating():
		navigation.set_new_pathfinding_location_relative_explicit_angle(entity.global_position, min_radius, max_radius, angle, 0)
	input.set_move_input_direction(navigation.get_next_path_direction())

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""
