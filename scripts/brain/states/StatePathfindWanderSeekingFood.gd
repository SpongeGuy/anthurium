extends BrainState
class_name StatePathfindWanderSeekingFood

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent

var min_wander_radius: float = 25
var max_wander_radius: float = 100

var wander_angle_variance: float = 90

# area search for item
var _search_timer: float = 0.0
var search_timer_duration: float = 2.0

var space_state: PhysicsDirectSpaceState2D

var found_food: bool

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	space_state = entity.get_world_2d().direct_space_state
	
	found_food = false
	
	if navigation.is_navigating():
		navigation.stop_navigation()

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	if not input.player_controlled:
		_handle_ai_movement(delta)
	_seek_food(delta)
	locomotion.handle_locomotion(delta)

func _handle_ai_movement(delta: float) -> void:
	var maxwr: float = max_wander_radius * brain.get_personality_value(Brain.PERSONALITY.ENERGY)
	if not navigation.is_navigating():
		navigation.set_new_pathfinding_location_relative_explicit_angle(entity.position, min_wander_radius, maxwr, facing.get_direction_angle(), wander_angle_variance)
	
	input.set_move_input_direction(navigation.get_next_path_direction()) 
	locomotion.handle_locomotion(delta)
	
func _seek_food(delta: float) -> void:
	_search_timer -= delta
	if _search_timer <= 0.0:
		_search_timer = search_timer_duration
	
	var nearby: Array[Entity] = SpatialUtil.get_entities_in_radius(space_state, entity.position, 120, SpatialUtil.PhysicsLayers.ITEMS)
	var nearest: Entity = SpatialUtil.get_nearest_entity_in_raycast_in_array(entity.position, nearby, space_state)
	
	if nearest:
		brain.set_memory(Brain.Memory.TARGET, nearest)
		found_food = true
		play_effect(&"on_found_food")

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	if found_food:
		return &"move_to_target"
	return &""

