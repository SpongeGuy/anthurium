extends BrainState
class_name StatePathfindWander

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler

var min_wander_radius: float = 25
var max_wander_radius: float = 100

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)

func exit() -> void:
	pass


func physics_process(delta: float) -> void:
	if not input.player_controlled:
		_handle_ai(delta)
	
	locomotion.handle_locomotion(delta)

func _handle_ai(delta: float) -> void:
	var mwr: float = max_wander_radius * brain.get_personality_value(Brain.PERSONALITY.ENERGY)
	if not navigation.is_navigating():
		navigation.set_new_pathfinding_location_relative(entity.position, min_wander_radius, mwr)
	
	input.set_move_input_direction(navigation.get_next_path_direction())


## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""

