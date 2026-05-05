extends BehaviorState
class_name PressTheAttackState

@export var input: InputComponent
@export var action_id: int = 0


func enter() -> void:
	input.press_action(action_id)
	
func update(delta: float) -> void:
	pass
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	input.release_action(action_id)
