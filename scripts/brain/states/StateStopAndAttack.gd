extends BrainState
class_name StateStopAndAttack

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler
var facing: FacingComponent
var ability_manager: AbilityManager
var ability_to_use: int = 0

var radius: float = 16

var _timer: float = 0.0
var ability_use_timer: float = 2.0

var target: Entity

var attack_effect: EntityEffect

var timer_jitter: float = 1

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	facing = entity.get_component(FacingComponent)
	
	if navigation.is_navigating():
		navigation.stop_navigation()
		
	_timer = ability_use_timer + randf_range(-timer_jitter, timer_jitter)
		
	play_effect(&"on_enter")
	
	
	input.set_move_input_direction(Vector2.ZERO)

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	target = brain.get_memory(Brain.Memory.THREAT)
	if is_instance_valid(target):
		_handle_ai_behavior(delta)
	locomotion.handle_locomotion(delta)
	
		
func _handle_ai_behavior(delta: float) -> void:
	facing.set_direction_angle(SpatialUtil.get_angle_between_entities(entity, target))
	_timer -= delta
	if _timer <= 0.0:
		try_play_effect(attack_effect)
		_timer = ability_use_timer + randf_range(-timer_jitter, timer_jitter)
		input.press_action(0)
		input.release_action(0)
	

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""

