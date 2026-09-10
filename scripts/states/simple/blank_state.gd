extends BehaviorState
class_name BlankState
## states should only include logic which alters data.
## all other functions should be outsourced to other components, such as visual effects or sounds.

## called once when the state machine does its initial switch to this state
func enter() -> void:
	pass
	
## called every frame while this state is active
func update(delta: float) -> void:
	pass
	
## called every physics frame while this state is active
func physics_update(delta: float) -> void:
	pass
	
## called once when this state is switched from
func exit() -> void:
	pass

