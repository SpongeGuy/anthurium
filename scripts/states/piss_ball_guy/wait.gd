extends BehaviorState
class_name WaitState

@export var min_time: float = 0.0
@export var max_time: float = 0.0
@export var facing: FacingComponent
@export var next_state: BehaviorState

var _timer: float = 0.0

func enter() -> void:
	_timer = randf_range(min_time, max_time)
	if facing:
		facing.change_direction(Vector2.RIGHT)
	
func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		state_machine.switch(next_state)
	
func physics_update(delta: float) -> void:
	pass
	
func exit() -> void:
	pass
