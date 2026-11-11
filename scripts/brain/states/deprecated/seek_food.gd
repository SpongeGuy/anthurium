extends BehaviorState
class_name StateSeekFood
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.

@export var input: InputComponent
@export var memory: Memory
@export var navigation: NavigationHelper
@export var locomotion: LocomotionHandler
@export var food_scan_timer: float = 2.0
@export var food_scan_radius: float = 120

@export var next_state: BehaviorState

var _food_scan_timer: float = 0.0

var space_state: PhysicsDirectSpaceState2D

## called once when the state machine does its initial switch to this state
func enter() -> void:
	space_state = state_machine.entity.get_world_2d().direct_space_state
	
## called every frame while this state is active
func update(delta: float) -> void:
	pass
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	if input.player_controlled:
		return
	
	var nearby: Array[Entity] = SpatialUtil.get_entities_in_radius(space_state, state_machine.entity.position, 120, SpatialUtil.PhysicsLayers.ITEMS)
	var nearest: Entity = SpatialUtil.get_nearest_entity_in_raycast_in_array(state_machine.entity.position, nearby, space_state)
	if nearest:
		navigation.set_new_pathfinding_location_explicit(nearest.position)
	
	input.move_input_direction = navigation.get_next_path_direction()
	locomotion.handle_locomotion(delta)

	if SpatialUtil.is_within_distance_of_entity(state_machine.entity, nearest, 10):
		state_machine.switch(next_state)
	
	
## called once when this state is switched from
func exit() -> void:
	pass

