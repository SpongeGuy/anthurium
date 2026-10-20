extends BrainState
class_name StatePathfindWanderOccasionallyEffect

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent

var min_wander_radius: float = 25
var max_wander_radius: float = 100

var _timer: float = 0.0
var timer_length: float = 3.0
var timer_base_length: float = 3.0

var rng: RandomNumberGenerator

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	rng = RunRng.get_stream(&"entity")
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	
	if navigation.is_navigating():
		navigation.stop_navigation()
		
	play_effect(&"on_enter")
	
	_timer = RandomUtil.randomize_float_with_personality(rng, timer_base_length, 0.5, 1 - brain.get_personality_value(Brain.PERSONALITY.ENERGY), 2.0)

func exit() -> void:
	pass


func physics_process(delta: float) -> void:
	if not input.player_controlled:
		_handle_ai_movement(delta)
		
	_timer -= delta
	if _timer <= 0:
		_timer = RandomUtil.randomize_float_with_personality(rng, timer_base_length, 0.5, 1 - brain.get_personality_value(Brain.PERSONALITY.ENERGY), 2.0)
		play_effect(&"on_timer")
	
	locomotion.handle_locomotion(delta)

func _handle_ai_movement(delta: float) -> void:
	var mwr: float = max_wander_radius * brain.get_personality_value(Brain.PERSONALITY.ENERGY)
	if not navigation.is_navigating():
		
		var target_location: Vector2 = navigation.set_new_pathfinding_location_relative(entity.global_position, min_wander_radius, mwr)
		facing.set_direction_angle(SpatialUtil.get_angle_between_positions(entity.global_position, target_location))
	
	input.set_move_input_direction(navigation.get_next_path_direction())


## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""
