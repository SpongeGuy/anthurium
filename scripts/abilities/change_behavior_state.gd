extends Ability
class_name AbilityChangeBehaviorState

@export var behavior_state: BehaviorState
@export var state_machine: StateMachine

func on_pressed() -> void:
	execute()
	
func on_held(hold_duration: float, delta: float) -> void:
	pass
	
func on_released(hold_duration: float) -> void:
	pass

## actually execute the ability
## this is where custom logic for the ability will go
func _execute() -> void:
	state_machine.switch(behavior_state)

