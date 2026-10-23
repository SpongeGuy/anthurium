extends BrainState
class_name StatePathfindWander

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent

var min_wander_radius: float = 25
var max_wander_radius: float = 100



func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	
	if navigation.is_navigating():
		navigation.stop_navigation()
		
		
	play_effect(&"on_enter")

func exit() -> void:
	pass


func physics_process(delta: float) -> void:
	if not input.player_controlled:
		_handle_ai_movement(delta)
	
	locomotion.handle_locomotion(delta)

func _handle_ai_movement(delta: float) -> void:
	var energy: float = brain.get_personality_value(Brain.PERSONALITY.ENERGY)
	var mwr: float = maxf(max_wander_radius * energy, min_wander_radius + 8.0)
	if not navigation.is_navigating():
		
		var target_location: Vector2 = navigation.set_new_pathfinding_location_relative(entity.global_position, min_wander_radius, mwr)
		if entity.basename == "gnawlfy":
			var map := navigation.navigation.get_navigation_map()
			var neighbor := entity.global_position + Vector2(-16, 0)
			var r_self := NavigationServer2D.map_get_closest_point_owner(map, entity.global_position)
			var r_nb := NavigationServer2D.map_get_closest_point_owner(map, neighbor)
			print("margin=", NavigationServer2D.map_get_edge_connection_margin(map),
				" self_conns=", NavigationServer2D.region_get_connections_count(r_self),
				" nb_conns=", NavigationServer2D.region_get_connections_count(r_nb),
				" same_region=", r_self == r_nb,
				" self_enabled=", NavigationServer2D.region_get_enabled(r_self),
				" nb_enabled=", NavigationServer2D.region_get_enabled(r_nb),
				" self_layers=", NavigationServer2D.region_get_navigation_layers(r_self),
				" nb_layers=", NavigationServer2D.region_get_navigation_layers(r_nb),
				" agent_layers=", navigation.navigation.navigation_layers)
		facing.set_direction_angle(SpatialUtil.get_angle_between_positions(entity.global_position, target_location))
	
	input.set_move_input_direction(navigation.get_next_path_direction())


## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""
