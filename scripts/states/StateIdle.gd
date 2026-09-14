extends BrainState

var navigation: NavigationHelper
var input: InputComponent
var locomotion: LocomotionHandler

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	navigation = entity.get_component(NavigationHelper)
	input = entity.get_component(InputComponent)
	locomotion = entity.get_component(LocomotionHandler)
	
	if navigation.is_navigating():
		navigation.stop_navigation()

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	if not input.player_controlled:
		_handle_ai_movement()
		
	locomotion.handle_locomotion(delta)
	
func _handle_ai_movement() -> void:
	input.set_move_input_direction(Vector2.ZERO)

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""

