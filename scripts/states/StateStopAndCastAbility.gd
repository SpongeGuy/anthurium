extends BrainState
class_name StateStopAndCastAbility

var ichor: IchorComponent
var input: InputComponent
var ability_man: AbilityManager

var _timer: float
var cast_timer: float = 2.0

var rng: RandomNumberGenerator

func _init(e: Entity, b: Brain) -> void:
	super._init(e, b)

func enter() -> void:
	rng = RunRng.get_stream(&"entity")
	ichor = entity.get_component(IchorComponent)
	input = entity.get_component(InputComponent)
	
	input.set_move_input_direction(Vector2.ZERO)
	
	_timer = cast_timer + rng.randf_range(-2, 2)
	

func exit() -> void:
	pass

func physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		play_effect("cast_ability")
		_timer = cast_timer + rng.randf_range(-2, 2)
	

## return teh StringName of the state to transition to, or &"" to stay.
## called every tick by the owning StateMachine after physics_process
func get_transition() -> StringName:
	return &""
