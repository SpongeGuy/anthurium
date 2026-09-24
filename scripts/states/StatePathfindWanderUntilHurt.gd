extends BrainState
class_name StatePathfindWanderUntilHurt

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent
var health: HealthComponent

var min_wander_radius: float = 25
var max_wander_radius: float = 100

var triggered: bool = false

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	health = entity.get_component(HealthComponent)
	
	if navigation.is_navigating():
		navigation.stop_navigation()
		
	triggered = false
		
	play_effect(&"on_enter")
	
	health.taken_damage.connect(_on_taken_damage)

func exit() -> void:
	pass


func physics_process(delta: float) -> void:
	if not input.player_controlled:
		_handle_ai_movement(delta)
	
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
	if triggered:
		return &"triggered"
	return &""


func _on_taken_damage(amount: float, source: Entity) -> void:
	triggered = true
