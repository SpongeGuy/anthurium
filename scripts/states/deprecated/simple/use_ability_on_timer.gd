extends BehaviorState
class_name StateUseAbilityOnTimer
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.

@export var input: InputComponent
@export var ability_to_use: int = 0
@export var min_timer: float = 3.0
@export var max_timer: float = 3.0

var _timer: float

## called once when the state machine does its initial switch to this state
func enter() -> void:
	_timer = randf_range(min_timer, max_timer)
	
## called every frame while this state is active
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		input.press_action(0)
		input.release_action(0)
	
## called every physics frame while this state is active 
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass

